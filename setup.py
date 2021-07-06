#!/usr/bin/python3
"""
Setuptools configuration for monitor.
"""
from cdn_build import cdn_setup as setup

if __name__ == "__main__":
    DIST_NAME = "skeleton"
    setup(
        name=DIST_NAME,
        entry_points={"console_scripts": ["start_%s=skeleton.start:main" % DIST_NAME]},
    )
