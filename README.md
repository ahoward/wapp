# TL;DR;

## LET'S DO THIS

- * INITIALIZE SENV *
  - rm -rf .senv && ./bin/senv .setup
  - ./bin/senv .edit .senv/all.rb

  ```ruby
  # you will need to add the URL of your repo
    ENV['REPO'] = 'https://github.com/your/repo-name'
  ```

- * DOCKER THAT SHIT UP *
  - ./docker/build
  - ./docker/run
  - ./docker/dev

## DEPS

- docker
- git
- ruby

## RUBY / NODE VERSIONS

- master .ruby-version and .nvmrc live in ./docker/.ruby-version and
  ./docker/.nvmrc, in other areas of the project one should *make symlinks* to
  these to keep them in sync.  eg, ./backend/.ruby-version ->
  ../docker/.ruby-version

- technically *any* of ruby can be used to run the scripts on ./docker/ but
  life is a lot simpler if you ensure having the versions of ruby and node the
  project wants on the host system.  learning to use your ruby/node version
  manager is outside the scope of this doc.

## LAYOUT

### ./docker

All scripts required to configure, build, and run the docker container.
these are written in ultra-portable ruby + bash.  You shouldn't need any
particular version of either to run ./docker/build but life is simpler if you
have it installed.

The docker tooling is setup to build two targets: _development_ and
_production_.  The purpose of having two targets is exclusively to support
have some development-only tools installed into that container such as tmux,
vim, or other things that make local development nicer but the container
balloon in size.  Keep development only additions to an absolute minimim and
try to keep production/development parity ultra tight WRT to the containers.
We do not want to need to write tests for operating systems.

## GO DOCKER GO!

```sh

  # build it yo.  note that the build scripts support the notion of a
  # 'target'.  this means a dedicated build.  the default builds keep
  # development and production *identical* and this should be a goal for
  # future development to ease verification that the production image
  # functions like the develpment image and that each variant is, therefore,
  # the same and meets the same PCI compliance goals.  so, for example, avoid
  # putting development only deps into the development built unlesa absolutely
  # necessary.
  # 
  # also note: when target==development the app root is mounted to /app and
  # the $CWD is set to /app such that 'local chagnes', such as to code, appear
  # in the container without re-building it.  in production the entire
  # application bundle is copied into the container in the _normal_ fashion.

    ./docker/build

    target=production ./docker/build

    target=development ./docker/build

  # run it yo.  note that all ./docker/* command respect the target=$ format
  #

    ./docker/run

    target=production ./docker/run

    target=develpment ./docker/run

  # shell into it yo
  #

    ./docker/shell

  # just spit out the stupid Dockerfile on STDOUT.  note, most deployment
  # targets require a file named 'Dockerfile' at the project root so this
  # command would often be the first step of a deploy script
  #

    target=production ./docker/file > Dockerfile

    target=production ./docker/file > Dockerfile.production

    target=development ./docker/file > Dockerfile.development


  # in development mode the ./docker/* cmds mount '.' to /app and set $CWD to
  # /app and therefore things like this work AND RUN IN THE CONTAINER:
  #

    ./docker/run ./script/that-runs-in-the-container ./local-input

  # eg

    ./docker/run ./bin/sekrets read config/modes/development.yml.enc

```


### ENV

the docker container can be effected at runtime by setting three ENV vars,
these, along with thier default values are listed here.  all of these vars are
available *inside* the docker container and are set in ./docker/config for all
./docker/$ scripts.

```bash
  PORT=${8080}

  MODE=${development}

  SEKRETS_KEY=
```

#### GROK TEH SEKRETS_KEY

  the SEKRETS_KEY deserves special attention.

  - because the application is deployed via docker
  - and the deploy target can likely start/stop nodes at any time, eg, heroku,
    google-cloud-run, or aws-fargate
  - the key cannot reside in memory, but must be fetched at container launch
    time

  the application is (often) setup for three 'modes'

  - development
  - staging
  - production

  three *sets* of config files exist to configure the app for each of these
  environments

  - development
    - ./config/modes/development.rb
    - ./config/modes/development.yml.enc

  - staging
    - ./config/modes/staging.rb
    - ./config/modes/staging.yml.enc

  - production
    - ./config/modes/production.rb
    - ./config/modes/production.yml.enc


  for each of the sets the dynamic ($.rb) config runs before the static and
  encrypted config ($.yml.enc), thus, those ($.rb) is the place to acquire and
  set any dynamic/in-memory only ENV vars, such as the SEKRETS_KEY var.
  please see ./config/modes/development.rb for an example of this, it fetches
  the key from local disk to ease local development but, for staging and
  production, this key will be fetched safely and securely from a remote
  service of some sort and relayed into the ennvironment. see
  ./config/modes/staging.rb and ./config/modes/production.rb for reference.

  when setup correctly the following should work

  ```bash
    ~> ./docker/shell

    ~docker-prompt> SEKRETS_KEY=abc ./bin/sekrets read config/modes/development.yml.enc

    ~docker-prompt> SEKRETS_KEY=xyz ./bin/sekrets read config/modes/staging.yml.enc

    ~docker-prompt> SEKRETS_KEY=123 ./bin/sekrets read config/modes/production.yml.enc
    
  ```

  which is to say you should have 3 encrypted files, each encrypted with a
  different key resident in the repo.

## MISC/NOTES
 
 
 
 
 
