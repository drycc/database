#!/usr/bin/env bash

# ensure WAL log bucket exists
envdir "$WALG_ENVDIR" create_bucket
