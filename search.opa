
import stdlib.web.client
import stdlib.core.xhtml
import stdlib.core.xmlm

type item = { option(string) title, option(string) link, option(string) guid, option(string) description, option(string) pubDate }

type search_params = {
  string auth,
  list(string) args,
  int ps,
  int p
}

module Search {

  auth = ""

  init_params = { auth:auth, ps:2, p:1, args:["Why I should do a search before calling next"] }

  (UserContext.t(search_params)) params = UserContext.make(init_params)

  function get_auth() { UserContext.execute(function (sp) { sp.auth },params); }
  function set_auth(option(string) auth) {
    UserContext.change_or_destroy(function (state) { Option.map(function (auth) { {state with ~auth} },auth); },params);
  }
  function get_args() { UserContext.execute(function (sp) { sp.args },params); }
  function set_args(option(list(string)) args) {
    UserContext.change_or_destroy(function (state) { Option.map(function (args) { {state with ~args} },args); },params);
  }
  function get_ps() { UserContext.execute(function (sp) { sp.ps },params); }
  function set_ps(option(int) ps) {
    UserContext.change_or_destroy(function (state) { Option.map(function (ps) { {state with ~ps} },ps); },params);
  }
  function get_p() { UserContext.execute(function (sp) { sp.p },params); }
  function set_p(option(int) p) {
    UserContext.change_or_destroy(function (state) { Option.map(function (p) { {state with ~p} },p); },params);
  }

  function get_search(list(string) args) {
    query = String.concat(" ",args);
    options = ["/rss","/ps={get_ps()}","/p={get_p()}"];
    q = query^" "^String.concat(" ",options);
    uri = Uri.of_absolute(
                          { Uri.default_absolute with
                              schema:{some:"https"},
                              domain:"blekko.com",
                              path:["ws"],
                              query:[("q",q),("auth",get_auth())]
                          });
    jlog("uri={Uri.to_string(uri)}");
    (xhtml) match (WebClient.Get.try_get(uri)) {
      case {failure:f}: <>"{f}"</>;
      case {success:result}:
        match (Xmlm.try_parse(result.content)) {
          case {some:xmlm}:
            match (dig(xmlm)) {
              case {success:(title,items)}: format_items(title,items);
              case {failure:f}: <>{f}</>
            };
          case {none}: <>"No XML found"</>;
        };
    }
  }

  function search(list(string) args) {
    set_p({some:1});
    set_args({some:args});
    get_search(args)
  }

  function next() {
    set_p({some:get_p()+1});
    get_search(get_args())
  }

  function prev() {
    set_p({some:Int.max(1,get_p()-1)});
    get_search(get_args())
  }

  function page(int pagenum) {
    set_p({some:pagenum});
    get_search(get_args())
  }

  function set(list(string) args) {
    match (args) {
      case ["auth",auth]: set_auth({some:auth}); <>set auth to {auth}</>
      case ["ps",ps]:
        match (Calc.nat_of_string(ps)) {
          case {some:ps}:
            set_ps({some:ps}); <>set ps to {ps}</>
          case {none}: <>set ps &lt;int&gt;</>
        };
      case args: <>Unknown set params {List.to_string(args)}</>
    }
  }

  function get_tag(xml('a,'b) xml_) { match (xml_) { case {~tag, ...}: tag; default: "no_tag"; } }
  function get_content(option(xml('a,'b)) xml_) { match (xml_) { case {some:{~content, ...}}: {some:content}; default: none; } }
  /*function get_text(option(xml('a,'b)) xml_) {
    match (xml_) { case {some:{content:[{~text}], ...}, ...}: {some:text}; default: none; }
  }*/
  function is_tag(string t)(xml('a,'b) xml_) { match (xml_) { case {~tag, ...}: t == tag; default: false; } }
  function single_tag(string t, list(xml('a,'b)) content) { List.find(is_tag(t), content) }
  function find_tags(string t, list(xml('a,'b)) content) { List.filter(is_tag(t),content) }

  function get_text(option(xml('a,'b)) xml_) {
    match (xml_) {
      case {some:{args:_, content:[{~text}], namespace:_, specific_attributes:_, tag:_}}: {some:text};
      default: none;
    }
  }

  function lo2l(list(option('a)) ol) {
    recursive function aux(list(option('a)) ol,(list('a)) l) {
      match (ol) {
        case [{some:e}|t]: (list('a)) aux(t,[e|l]);
        case [{none}|t]: (list('a)) aux(t,l);
        case []: (list('a)) l;
      }
    }
    (list('a)) List.rev(aux(ol,[]));
  }

  function dig(xmlns xmlns) {
    //jlog("xmlns:{xmlns}");
    match (xmlns) {
      case {~text}: {failure:text};
      case {~content_unsafe}: {failure:content_unsafe};
      case {fragment:_}: {failure:"fragment"};
      case {xml_dialect:_}: {failure:"xml_dialect"};
      case {args:_, ~content, namespace:_, specific_attributes:_, tag:"rss"}:
        match (get_content(single_tag("channel",content))) {
          case {some:content}:
            title = get_text(single_tag("title",content));
            //tags = List.map(get_tag,content);
            //jlog("tags:{List.to_string(tags)}");
            items = find_tags("item",content);
            {success:(title,lo2l(List.map(get_item,items)))};
          default: {failure:"no channel"};
        };
      default: {failure:"no rss"};
    }
  }

/*
{args = [];
 content = [{args = []; content = [{text = /coenvalk/food}]; namespace = ; specific_attributes = {none = {}}; tag = title},
            {args = []; content = [{text = http:/blekko.com/ws/view+/coenvalk/food}]; namespace = ; specific_attributes = {none = {}}; tag = link},
            {args = []; content = [{text = http:/blekko.com/ws/view+/coenvalk/food}]; namespace = ; specific_attributes = {none = {}}; tag = guid},
            {args = []; content = [{text = food, eating, cook, bake}]; namespace = ; specific_attributes = {none = {}}; tag = description}];
  namespace = ; specific_attributes = {none = {}}; tag = item}

            content:[{args:_, content:[{text:title}], namespace:_, specific_attributes:_, tag:"title"},
                     {args:_, content:[{text:link}], namespace:_, specific_attributes:_, tag:"link"},
                     {args:_, content:[{text:guid}], namespace:_, specific_attributes:_, tag:"guid"},
                     {args:_, content:[{text:description}], namespace:_, specific_attributes:_, tag:"description"},
                     {args:_, content:[{text:pubDate}], namespace:_, specific_attributes:_, tag:"pubDate"}],
*/

  function get_item(xml('a,'b) xml_) {
    //jlog("xml_:{xml_}");
    match (xml_) {
      case {args:_,~content, namespace:_, specific_attributes:_, tag:"item"}:
        title = get_text(single_tag("title",content))
        link = get_text(single_tag("link",content))
        guid = get_text(single_tag("guid",content))
        description = get_text(single_tag("description",content))
        pubDate = get_text(single_tag("pubDate",content))
        {some:(item) ~{title, link, guid, description, pubDate}};
      default: none;
    }
  }

  function decode(string str) {
    // There must be a function to do this somewhere in OPA!
    str =  String.replace("&amp;","&",str);
    str =  String.replace("&amp;","&",str);
    str =  String.replace("&quot;","\"",str);
    str =  String.replace("&#39;","'",str);
    str
  }

  function format_items(option(string) title, list(item) items) {
    pageno = get_p();
    base = (get_ps())*(pageno-1)+1;
    page = if (pageno != 1) " page {pageno}" else "";
    title =
      match (title) {
        case {some:title}: <h5 class="search-main-title">{decode(title^page)}</h5>
        case {none}: <></>
      };
    (xhtml) List.fold_backwards(compose_xhtml,List.rev(List.mapi(format_item(base),items)),title);
  }

  function encode_query(list((string,string)) query) {
    List.map(function ((x,y)) { (Uri.encode_string(x), Uri.encode_string(y)) }, query);
  }

  function encode_uri(string uri) {
     String.replace("+","%2B",uri);
  }

  function format_item(int base)(int n, item item) {
    title =
      match (item.title) {
        case {some:title}: <span class="search-title">{decode(title)}</span>
        case {none}: <></>
      };
    description =
      match (item.description) {
        case {some:description}: <span class="search-description">{decode(description)}</span>
        case {none}: <></>
      };
    link =
      match (item.link) {
        case {some:link}:
          link = decode(link);
          d =
            match (Parser.try_parse(UriParser.uri, link)) {
              case {some:uri}:
                jlog("uri:{uri}");
                match (uri) {
                  case ~{domain, ...}: domain;
                  default: link;
                };
              case res: jlog("failed to parse: {res}"); link;
            };
          link = Url.encode(Url.make(link));
          jlog("link={link} d={d}");
          <span class="search-link">(<a target="_blank" href="{link}">{d}</a>)</span>
        default: <></>
      }
    pubDate =
      match (item.pubDate) {
        case {some:pubDate}: <span class="search-pubDate">{decode(pubDate)}</span>
        case {none}: <></>
      };
    <div>
      <span class="search-index">{n+base}.</span>
      {title}
      {description}
      {link}
      {pubDate}
    </div>
  }

  function compose_xhtml(xhtml s, xhtml x) {
    <>{x}</>
    <+>
    <>{s}</>
  }

}

/*
xmlns:{args = [{name = version; namespace = ; value = 2.0}]; content = [{args = []; content = [{args = []; content = [{text = blekko | rss for &quot;cooking /findslashtag /rss /ps=2 /p=1&quot;}]; namespace = ; specific_attributes = {none = {}}; tag = title}, {args = []; content = [{text = http:/blekko.com/?q=cooking+%2Ffindslashtag+%2Frss+%2Fps%3D2+%2Fp%3D1}]; namespace = ; specific_attributes = {none = {}}; tag = link}, {args = []; content = [{text = Blekko search for &quot;cooking /findslashtag /rss /ps=2 /p=1&quot;}]; namespace = ; specific_attributes = {none = {}}; tag = description}, {args = []; content = [{text = en-us}]; namespace = ; specific_attributes = {none = {}}; tag = language}, {args = []; content = [{text = Copyright 2011 Blekko, Inc.}]; namespace = ; specific_attributes = {none = {}}; tag = copyright}, {args = []; content = [{text = http:/cyber.law.harvard.edu/rss/rss.html}]; namespace = ; specific_attributes = {none = {}}; tag = docs}, {args = []; content = [{text = webmaster@blekko.com}]; namespace = ; specific_attributes = {none = {}}; tag = webMaster}, {args = []; content = [{text = 265}]; namespace = ; specific_attributes = {none = {}}; tag = rescount}, {args = []; content = [{args = []; content = [{text = /tom/reviews}]; namespace = ; specific_attributes = {none = {}}; tag = title}, {args = []; content = [{text = http:/blekko.com/ws/view+/tom/reviews}]; namespace = ; specific_attributes = {none = {}}; tag = link}, {args = []; content = [{text = http:/blekko.com/ws/view+/tom/reviews}]; namespace = ; specific_attributes = {none = {}}; tag = guid}, {args = []; content = [{text = comma separated terms}]; namespace = ; specific_attributes = {none = {}}; tag= description}]; namespace = ; specific_attributes = {none = {}}; tag = item}, {args = []; content = [{args = []; content = [{text = /coenvalk/food}]; namespace = ; specific_attributes = {none = {}}; tag = title}, {args = []; content = [{text = http:/blekko.com/ws/view+/coenvalk/food}]; namespace = ; specific_attributes = {none = {}}; tag = link}, {args = []; content = [{text = http:/blekko.com/ws/view+/coenvalk/food}]; namespace = ; specific_attributes = {none = {}}; tag = guid}, {args = []; content = [{text = food, eating, cook, bake}]; namespace = ; specific_attributes = {none = {}}; tag = description}]; namespace = ; specific_attributes = {none = {}}; tag = item}]; namespace = ; specific_attributes = {none = {}}; tag = channel}]; namespace = ; specific_attributes = {none = {}}; tag = rss}
*/

/*
{args = [{name = version; namespace = ; value = 2.0}];
 content = [{args = [];
             content = [{args = [];
                         content = [{text = blekko | rss for &quot;/news helicopter /rss /ps=2&quot;}];
                         namespace = ;
                         specific_attributes = {none = {}};
                         tag = title},
                        {args = [];
                         content = [{text = http:/blekko.com/?q=%2Fnews+helicopter+%2Frss+%2Fps%3D2}];
                         namespace = ;
                         specific_attributes = {none = {}};
                         tag = link},
                        {args = [];
                         content = [{text = Blekko search for &quot;/news helicopter /rss /ps=2&quot;}];
                         namespace = ;
                         specific_attributes = {none = {}};
                         tag = description},
                        {args = [];
                         content = [{text = en-us}];
                         namespace = ;
                         specific_attributes = {none = {}};
                         tag = language},
                        {args = [];
                         content = [{text = Copyright 2011 Blekko, Inc.}];
                         namespace = ;
                         specific_attributes = {none = {}};
                         tag = copyright},
                        {args = [];
                         content = [{text = http:/cyber.law.harvard.edu/rss/rss.html}];
                         namespace = ;
                         specific_attributes = {none = {}};
                         tag = docs},
                        {args = [];
                         content = [{text = webmaster@blekko.com}];
                         namespace = ;
                         specific_attributes = {none = {}};
                         tag = webMaster},
                        {args = [];
                         content = [{text = 20K}];
                         namespace = ;
                         specific_attributes = {none = {}};
                         tag = rescount},
                        {args = [];
                         content = [{args = [];
                                     content = [{text = Trial begins in civil suit against Robinson Helicopter for 2006 crash - The Daily Breeze}];
                                     namespace = ;
                                     specific_attributes = {none = {}};
                                     tag = title},
                                    {args = [];
                                     content = [{text = http:/www.dailybreeze.com/news/ci_19822166?source=rss}];
                                     namespace = ;
                                     specific_attributes = {none = {}};
                                     tag = link},
                                    {args = [];
                                     content = [{text = "http:/www.dailybreeze.com/news/ci_19822166?source=rss Wed, 25 Jan 2012 20:38:43 -0800"}];
                                     namespace = ;
                                     specific_attributes = {none = {}};
                                     tag = guid},
                                    {args = [];
                                     content = [{text = But according to Robinson Helicopter&amp;
                                    #39;
                                    s Raymond Hane, the likely cause of the accident was that Verellen entrusted the controls to Straatman, who did not have a pilot&amp;
                                    #39;
                                    s license. He said a Robinson test pilot checked out. The chopper before the keys were turned over to Verellen.}];
                                     namespace = ;
                                     specific_attributes = {none = {}};
                                     tag = description},
                                    {args = [];
                                     content = [{text = Wed, 25 Jan 2012 20:38:43 -0800}];
                                     namespace = ;
                                     specific_attributes = {none = {}};
                                     tag = pubDate}];
                         namespace = ;
                         specific_attributes = {none = {}};
                         tag = item},
                        {args = [];
                         content = [{args = [];
                                     content = [{text = Eurocopter Eyes Brazil Helicopter Exports By 2025 - Gannett Government Media - defensenews.com}];
                                     namespace = ;
                                     specific_attributes = {none = {}};
                                     tag = title},
                                    {args = [];
                                     content = [{text = http:/www.defensenews.com/article/20120125/DEFREG01/301250013/Eurocopter-Eyes-Brazil-Helicopter-Exports-By-2025?odyssey=tab%7Ctopnews%7Ctext%7CFRONTPAGE}];
                                     namespace = ;
                                     specific_attributes = {none = {}};
                                     tag = link},
                                    {args = [];
                                     content = [{text = http:/www.defensenews.com/article/20120125/DEFREG01/301250013/Eurocopter-Eyes-Brazil-Helicopter-Exports-By-2025?odyssey=tab%7Ctopnews%7Ctext%7CFRONTPAGE Wed, 25 Jan 2012 16:14:12 -0800}];
                                     namespace = ;
                                     specific_attributes = {none = {}};
                                     tag = guid},
                                    {args = [];
                                     content =[{text = Currently, Eurocopter helicopters are designed in Europe. A Brazilian factory in Itajuba, Minas Gerais, only assembles Ecureuils helicopters.}];
                                     namespace = ;
                                     specific_attributes = {none = {}};
                                     tag = description},
                                    {args = [];
                                     content = [{text = Wed, 25 Jan 2012 16:14:12 -0800}];
                                     namespace = ;
                                     specific_attributes = {none = {}};
                                     tag = pubDate}];
                                   namespace = ;
                                   specific_attributes = {none = {}};
                                   tag = item}];
          namespace = ;
          specific_attributes = {none = {}};
          tag = channel}];
  namespace = ;
  specific_attributes = {none = {}};
  tag = rss}
*/

