# TL;DR;

```sh


  ### 1) to start, you will need the SENV encryption key
  ~> echo "the-secret-key-you-need-to-ask-for!" > .senv/.key

  ### 2) ensure you have the correct version of ruby setup
  ~> cat .ruby-version
  # install this ruby version however you manage that, prefer rbenv

  ### 3) ensure you have the correct version of node setup
  ~> cat .nvmrc
  # install this node version however you manage that, prefer nvm

  ### 4) install dependencies
  ~> ./script/build

  ### boot 'er up dawg!
  ~> ./script/server

  ### handy dev script (gots to learn tmux!)
  ~> gem install tmuxinator && ./script/dev


```
