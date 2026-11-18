#!/usr/bin/env python3
"""USGS M2M login and one MTL.txt download via NDVI.py."""

import importlib.util
import os
import shutil
import tempfile
import unittest
from datetime import datetime
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "ndvi_download", Path(__file__).with_name("NDVI.py"))
ndvi = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ndvi)

DATASET = "landsat_ot_c2_l2"
SAMPLE_FILE = "_MTL.txt"


class TestM2MDownload(unittest.TestCase):
    def test_login_and_download_sample(self):
        ndvi.apiKey = ndvi.prompt_ERS_login(ndvi.serviceUrl)
        list_id = "ndvi_smoke_" + datetime.now().strftime("%Y%m%d%H%M%S%f")
        out_dir = tempfile.mkdtemp(prefix="ndvi_m2m_")
        try:
            scenes = ndvi.sendRequest(ndvi.serviceUrl + "scene-search", {
                "datasetName": DATASET,
                "maxResults": 1,
                "metadataType": "full",
                "sceneFilter": {
                    "spatialFilter": {
                        "filterType": "mbr",
                        "lowerLeft": {"latitude": 31.8279, "longitude": -109.1929},
                        "upperRight": {"latitude": 32.027, "longitude": -108.9929},
                    },
                    "acquisitionFilter": {"start": "2025-11-20", "end": "2025-11-22"},
                    "cloudCoverFilter": {"min": 0, "max": 100},
                },
            }, ndvi.apiKey)
            entity_id = scenes["results"][0]["entityId"]
            ndvi.sendRequest(
                ndvi.serviceUrl + "scene-list-remove",
                {"listId": list_id}, ndvi.apiKey, False)
            ndvi.sendRequest(ndvi.serviceUrl + "scene-list-add", {
                "listId": list_id,
                "idField": "entityId",
                "entityIds": [entity_id],
                "datasetName": DATASET,
            }, ndvi.apiKey)
            products = ndvi.get_download_options(list_id, DATASET, True)
            item = next(
                secondary
                for product in products
                for secondary in product["secondaryDownloads"]
                if SAMPLE_FILE in secondary["displayId"])
            ndvi.label = datetime.now().strftime("%Y%m%d_%H%M%S")
            ndvi.threads = []
            requested = ndvi.run_download_request({
                "downloads": [{
                    "entityId": item["entityId"],
                    "productId": item["id"],
                }],
                "label": ndvi.label,
            })
            ndvi.run_download_retrieve(requested, out_dir)
            next(name for name in os.listdir(out_dir) if name.endswith(SAMPLE_FILE))
        finally:
            ndvi.sendRequest(
                ndvi.serviceUrl + "scene-list-remove",
                {"listId": list_id}, ndvi.apiKey, False)
            ndvi.sendRequest(ndvi.serviceUrl + "logout", None, ndvi.apiKey, False)
            shutil.rmtree(out_dir, ignore_errors=True)


if __name__ == "__main__":
    unittest.main(verbosity=2)
