#!/usr/bin/env lsc -cj
author: 'Chia-liang Kao'
name: 'lfrest'
description: 'lfrest'
version: '0.0.1'
repository:
  type: 'git'
  url: 'https://github.com/g0v/lfrest'
engines:
  node: '0.8.x'
  npm: '1.1.x'
scripts:
  prepublish: '''./node_modules/.bin/lsc -cj package.ls &&
  ./node_modules/.bin/lsc -bc -o lib src
'''
main: \lib/index.js
dependencies:
  async: \0.2.x
  optimist: \0.4.x
  express: \3.2.x
  nodemailer: \0.4.x
  pg: \2.0.x
  cors: \1.0.x
  pgrest: 'git://github.com/clkao/pgrest.git'
devDependencies:
  LiveScript: '1.1.x'
