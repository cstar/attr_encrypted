require 'test/unit'
require 'digest/sha2'
require 'rubygems'
require 'mocha'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.dirname(__FILE__))
require 'attr_encrypted'

