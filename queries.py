# pip install sparqlwrapper
# https://rdflib.github.io/sparqlwrapper/

import sys
import os
from SPARQLWrapper import SPARQLWrapper, JSON
import requests

endpoint_url = "https://query.wikidata.org/sparql"

get_buildings_query = """
SELECT ?item ?itemLabel ?value
{
#   wd:Q98930725 wdt:P3896 ?value .
  ?item p:P31 ?statement0.
  ?statement0 (ps:P31/(wdt:P279*)) wd:Q41176.
  ?item p:P361 ?statement1.
  ?statement1 (ps:P361/(wdt:P279*)) wd:Q464266.
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en,en"  }
}
LIMIT 1000"""


def get_results(endpoint_url, query):
    user_agent = "WDQS-example Python/%s.%s" % (sys.version_info[0], sys.version_info[1])
    # TODO adjust user agent; see https://w.wiki/CX6
    sparql = SPARQLWrapper(endpoint_url, agent=user_agent)
    sparql.setQuery(query)
    sparql.setReturnFormat(JSON)
    return sparql.query().convert()


results = get_results(endpoint_url, get_buildings_query)

for result in results["results"]["bindings"]:
    
    item_name = result["itemLabel"]["value"]
    item_id = result["item"]["value"].split("/")[-1]
    
    print(item_name)
    if os.path.isfile("geojsons" + os.sep + item_id + ".geojson"):
        print(item_id + f" ({item_name}) is already here, skipping...")
        continue
    
    get_geojson_query = '''
        SELECT ?item ?itemLabel ?value
        {
        '''+ f'     wd:{item_id} wdt:P3896 ?value.' + \
        '''
            SERVICE wikibase:label { bd:serviceParam wikibase:language "en, en" }
        }
        LIMIT 1
    '''
    
    geojson_query_results = get_results(endpoint_url, get_geojson_query)
    geojson_query_result_bindings = geojson_query_results["results"]["bindings"]
    
    if len(geojson_query_result_bindings) > 0:
    
        geojson_query_result = geojson_query_result_bindings[0]
        geojson_link = geojson_query_result["value"]["value"]
        geojson_result = requests.get(geojson_link)
    
        if geojson_result.status_code == 200:
            print("found, check geojsons" + os.sep + item_id + f' ({item_name})')
            open("geojsons" + os.sep + item_id + ".geojson", "w").write(geojson_result.text)
        else:
            print("...not found")
    
    else:
        print("...not found")
