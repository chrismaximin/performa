# Performa

[![Gem Version](https://badge.fury.io/rb/performa.svg)](https://badge.fury.io/rb/performa)
[![Build Status](https://travis-ci.org/christophemaximin/performa.svg?branch=master)](https://travis-ci.org/christophemaximin/performa)
[![Maintainability](https://api.codeclimate.com/v1/badges/95d351d4ba7400934b1b/maintainability)](https://codeclimate.com/github/christophemaximin/performa/maintainability)

**Performa** allows you to quickly run a script on a combination of docker images and staging commands.
It is fast, threadsafe, and has only one small external dependency (to [colorize](https://github.com/fazibear/colorize) the output).  

For example, Performa makes it trivial to run a benchmark on 3 versions of Ruby * 4 versions of ActiveRecord = 12 different environments.  
Because all environments are cached as docker images, running a different command on those 12 environments is relatively quick: 9 seconds on my `Intel(R) Core(TM) i7-4578U CPU @ 3.00GHz`.

## Installation

```sh
$ gem install performa
```

## Basic Usage

You can quickly generate an example config file by running `performa --init`.  
The default configuration is commented to describe all possible options and what to do with them:  

```yaml
---
## [Optional] Config file version (default: latest)
version: 1

## [Required] Base docker images to run command on
images:
  - ruby:2.4
  - ruby:2.5

## [Optional] Commands setting up each image before running command.
## Environments generated = images * stages
# stages:
#   activerecord_4:
#     - gem install sqlite3
#     - gem install activerecord -v=4.0.0
#   activerecord_5:
#     - gem install sqlite3
#     - gem install activerecord -v=5.0.0

## [Optional] Cache environments (as performa docker images)
# cache_environments: true

## [Optional] Volumes to mount
# volumes:
#   - .:/app

## [Required] Command to run on all environments
command: |
  ruby -e "puts RUBY_VERSION"

# [Optional] Where to output the command result
# Default value: STDOUT
# If you set it a directory, existing or not, that directory may be created,
# and the results will be put in individual files for each environment.
# output: STDOUT
# output: ./performa-results
```

Once you've finished setting up your configuration, you can run the command `performa`.

## Compatibility

Ruby >= 2.5

## License

Copyright (c) 2018-2019 Christophe Maximin. This software is released under the [MIT License](LICENSE.txt).
