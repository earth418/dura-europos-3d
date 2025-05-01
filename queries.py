# pip install sparqlwrapper
# https://rdflib.github.io/sparqlwrapper/

import sys
import os
from SPARQLWrapper import SPARQLWrapper, JSON
import requests
from urllib import request

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

def get_id_from_url(url):
    return url.split("/")[-1]

if True:

    results = get_results(endpoint_url, get_buildings_query)

    for result in results["results"]["bindings"]:
        
        item_name = result["itemLabel"]["value"]
        item_id = get_id_from_url(result["item"]["value"])
        
        print(item_name)
        # if os.path.isfile("geojsons" + os.sep + item_id + ".geojson"):
        #     print(item_id + f" ({item_name}) is already here, skipping...")
        #     continue
        
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
        print(geojson_query_results)
        
        if len(geojson_query_result_bindings) > 0:
        
            geojson_query_result = geojson_query_result_bindings[0]
            geojson_link = geojson_query_result["value"]["value"]
            # geojson_result = requests.get(geojson_link)
        
            print(geojson_link)
            # if geojson_result.status_code == 200:
            #     # print("found, check geojsons" + os.sep + item_id + f' ({item_name})')
            #     # open("geojsons" + os.sep + item_id + ".geojson", "w").write(geojson_result.text)
            # else:
            #     print("...not found")
        
        else:
            print("...not found")


if False:
    get_images_query = """
    #defaultView:Map
    SELECT ?object ?objectLabel ?place ?placeLabel ?coordinate ?image WHERE {
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
    ?object wdt:P31 wd:Q125191.
    ?object wdt:P5008 wd:Q114241199.
    ?object wdt:P180 ?place.
    ?place wdt:P625 ?coordinate.
    OPTIONAL { ?object wdt:P18 ?image. }
    }
    LIMIT 20000
    """

    images_results = get_results(endpoint_url, get_images_query)

    results_by_building = {}

    for result in images_results["results"]["bindings"]:
        # print(result)
        # print(result["place"])
        
        place = get_id_from_url(result["place"]["value"])
        if place not in results_by_building:
            results_by_building[place] = [result]
        else:
            results_by_building[place].append(result)

    # resetting each time
    # shutil.rmtree("images")
    # os.mkdir("images")

    for building_id, image_list in results_by_building.items():
        for image_info in image_list:
            _dir = "images" + os.sep + building_id
            image_objectid = get_id_from_url(image_info["object"]["value"])
        
            if not os.path.exists(_dir):
                os.mkdir(_dir)
            else:
                if os.path.isfile(_dir + os.sep + image_objectid + "_image_info.json"):
                    continue

            open(_dir + os.sep + image_objectid + "_image_info.json", "w").write(str(image_info))
            
            img_url = image_info["image"]["value"]
            image_ending = img_url.split("/")[-1].split(".")[-1]
            # urllib.urlretrieve()
            # with requests.get(img_url, stream=True) as img_result:
            
            # async def 
            # requests.urlopen()
            with open(_dir + os.sep + image_objectid + "." + image_ending, "wb") as imagef:
                img = request.urlopen(img_url)
                imagef.write(img.read())
                print(f"downloaded {_dir + os.sep + image_objectid + '.' + image_ending}")
                
            
            # filename = wget.download(img_url, out=(_dir + os.sep + image_objectid + "." + image_ending))
            # print(f"downloaded {filename}")
            # img_result = requests.get(img_url)
            # sleep(0.5)
            # if img_result.status_code == 200:
            #     print("image found!")
            #     with open(_dir + os.sep + image_objectid + "." + image_ending, "wb") as imagef:
            #         imagef.write(img_result.content)
            #         # for chunk in img_result:
            #             # imagef.write(chunk)                        
            # else:
            #     print("image not found :(")
