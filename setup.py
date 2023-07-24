#!/usr/bin/env python3
from setuptools import setup

setup(
    name="wlo-classification",
    version="0.1.0",
    description="A Python application",
    author="",
    author_email="",
    install_requires=[
        d for d in open("requirements.txt").readlines() if not d.startswith("--")
    ],
    package_dir={"": "src"},
    entry_points={
        "console_scripts": [
            "webservice = webservice:main",
            "training = training:main",
        ]
    },
)
