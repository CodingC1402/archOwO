#!/bin/bash

if [ -z "${DISPLAY}" ] && [ "${XDG_VTNR}" -eq 7 ]; then
  exec startxfce4
fi