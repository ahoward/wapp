#! /usr/bin/env ruby

# encoding: utf-8

require 'openssl'
require 'securerandom'
 
class Encryptor
  CIPHER_TYPE = 'AES-128-CBC'

  class << Encryptor
    attr :key
    attr :iv

    def configure(arg)
      config = parse_config(arg)
      @key = config[:key]
      @iv = config[:iv]
    end

    def parse_config(arg)
      config = arg.to_h

      key = config[:key] || config['key']
      iv = config[:iv] || config['iv']

      if key
        key = key.to_s
      end

      if iv
        iv = iv.to_s
      end

      {:key => key, :iv => iv}
    end

    def generate_cipher
      OpenSSL::Cipher.new(CIPHER_TYPE)
    end

    def generate_config
      cipher = generate_cipher
      key = random_bytes(cipher.random_key.size)
      iv = random_bytes(cipher.random_iv.size)
      {:key => key, :iv => iv}
    end

    def random_key
      cipher = generate_cipher
      key = random_bytes(cipher.random_key.size)
    end

    def random_iv
      cipher = generate_cipher
      key = random_bytes(cipher.random_iv.size)
    end

    def random_bytes(size)
      SecureRandom.urlsafe_base64(size).bytes[0, size].map(&:chr).join
    end

    def encrypt(data, key = Encryptor.key, iv = Encryptor.iv)
      cipher = generate_cipher
      cipher.encrypt
      cipher.key = key if key
      cipher.iv = iv if iv
      cipher.update(data.to_s) + cipher.final
    end

    def decrypt(data, key = Encryptor.key, iv = Encryptor.iv)
      cipher = generate_cipher
      cipher.decrypt
      cipher.key = key if key
      cipher.iv = iv if iv
      cipher.update(data.to_s) + cipher.final
    end

    def cycle(data, key = Encryptor.key, iv = Encryptor.iv)
      decrypt(encrypt(data, key, iv), key, iv)
    end
  end

  attr :key
  attr :iv

  def initialize(arg, *args)
    config =
      Encryptor.parse_config(
        if args.size.zero?
          arg
        else
          {:key => arg, :iv => args.first}
        end
      )

      @key = config[:key]
      @iv = config[:iv]
    end

  def encrypt(data)
    Encryptor.encrypt(data, @key, @iv)
  end

  def decrypt(data)
    Encryptor.decrypt(data, @key, @iv)
  end

  def cycle(data)
    decrypt(encrypt(data))
  end
end







if $0 == __FILE__
  original_data = '42 // forty-two'.freeze
  pp :original_data => original_data

  configs = Array.new(4){ Encryptor.generate_config }

  config = configs[0]
  key = config[:key]
  iv = config[:iv]
  pp :config => config, :key => key, :iv => iv

  class_with_config = Encryptor.dup
  class_with_config.configure(configs[1])

  objects = { 
    :class_without_config => Encryptor,
    :class_with_config => class_with_config,
    :instance_with_config => Encryptor.new(configs[2]),
    :instance_with_args => Encryptor.new(configs[3].slice(:key, :iv)),
  }

  args_for = proc do |object, args|
    object.is_a?(Class) ? args : args.first(1)
  end

  puts '==='
  objects.each do |type, object|
    data = original_data.dup
    puts '---'
    pp :type => type, :key => object.key, :iv => object.iv

    [:encrypt, :decrypt, :cycle].each do |method|
      args = args_for[object, [data, key, iv]]
      data = object.send(method, *args)
      puts '-'
      pp method => data, :args => args
    end
  end

  #puts 'Encryptor.key' => Encryptor.key, 'Encryptor.iv' => Encryptor.iv
end


__END__

➜ ruby ./lib/encryptor.rb
{:original_data=>"42 // forty-two"}
{:config=>{:key=>"3oqWjnr3d9lw5zMi", :iv=>"WPNXQVujcGOGAS05"}, :key=>"3oqWjnr3d9lw5zMi", :iv=>"WPNXQVujcGOGAS05"}
===
  ---
  {:type=>:class_without_config, :key=>nil, :iv=>nil}
-
  {:encrypt=>"\xAB4\x16\x8B\xAE\xC7#\xED!0\x85\x89,JM\xA7", :args=>["42 // forty-two", "3oqWjnr3d9lw5zMi", "WPNXQVujcGOGAS05"]}
-
  {:decrypt=>"42 // forty-two", :args=>["\xAB4\x16\x8B\xAE\xC7#\xED!0\x85\x89,JM\xA7", "3oqWjnr3d9lw5zMi", "WPNXQVujcGOGAS05"]}
-
  {:cycle=>"42 // forty-two", :args=>["42 // forty-two", "3oqWjnr3d9lw5zMi", "WPNXQVujcGOGAS05"]}
---
  {:type=>:class_with_config, :key=>"ssNaROt1NY5OSYRo", :iv=>"D64TOQwJPtKshLpb"}
-
  {:encrypt=>"\xAB4\x16\x8B\xAE\xC7#\xED!0\x85\x89,JM\xA7", :args=>["42 // forty-two", "3oqWjnr3d9lw5zMi", "WPNXQVujcGOGAS05"]}
-
  {:decrypt=>"42 // forty-two", :args=>["\xAB4\x16\x8B\xAE\xC7#\xED!0\x85\x89,JM\xA7", "3oqWjnr3d9lw5zMi", "WPNXQVujcGOGAS05"]}
-
  {:cycle=>"42 // forty-two", :args=>["42 // forty-two", "3oqWjnr3d9lw5zMi", "WPNXQVujcGOGAS05"]}
---
  {:type=>:instance_with_config, :key=>"DjW_l6t8P6VUpBcw", :iv=>"p9iw3GOH7r11h5Ap"}
-
  {:encrypt=>" \xF4\xFB`\xE7n\xB5p\xF1=e&~\xFD\b%", :args=>["42 // forty-two"]}
-
  {:decrypt=>"42 // forty-two", :args=>[" \xF4\xFB`\xE7n\xB5p\xF1=e&~\xFD\b%"]}
-
  {:cycle=>"42 // forty-two", :args=>["42 // forty-two"]}
---
  {:type=>:instance_with_args, :key=>"Act29o6LoyBADTQp", :iv=>"URiXw345vrWMyzgU"}
-
  {:encrypt=>"\x99\xE1\x81s\x88\xD7H\x92jJ\xD7,\x10\xD5C\x8B", :args=>["42 // forty-two"]}
-
  {:decrypt=>"42 // forty-two", :args=>["\x99\xE1\x81s\x88\xD7H\x92jJ\xD7,\x10\xD5C\x8B"]}
-
  {:cycle=>"42 // forty-two", :args=>["42 // forty-two"]}
