# frozen_string_literal: true

require 'spec_helper'
require 'world_factory'

class Author
  attr_reader :name

  def initialize(name:, books: [])
    @name = name
    @books = books
  end
end

class Book
  attr_reader :title, :author

  def initialize(title:, author:)
    @title = title
    @author = author
  end
end

module AuthorFactory
  extend WorldFactory::FactoryModule

  define_group :author do |f|
    f.member :default_author do |options = {}|
      Author.new(name: "Author McNeil")
    end
  end
end

module BooksFactory
  extend WorldFactory::FactoryModule

  define_group :book do |f|
    f.member :default_book do |options = {}|
      create_book_shared(**options)
    end

    f.member :fantasy_novel do |options = {}|
      create_book_shared(
        title: "Ring of the Lords",
        **options,
      )
    end

    f.member :technical_writeup do |options = {}|
      create_book_shared(options)
    end
  end

  def create_book_shared(**options)
    Book.new(
      author: options.fetch(:author) { assure_default_author },
      title: options.fetch(:title, "Book Title"),
    )
  end

  def method_on_book_module
    self
  end
end

class World < WorldFactory::BaseWorld
  include AuthorFactory
  include BooksFactory

  def method_on_world
    self
  end
end

describe WorldFactory do
  describe "defining factories" do
    it "works" do
      w = World.new
      author = w.add_default_author
      expect(author.name).to eq "Author McNeil"
      expect(w.author).to eq author
      expect(w.authors).to eq [author]

      expect(w.books).to eq []
      book = w.add_default_book(title: "Fun Book")
      expect(book.title).to eq "Fun Book"
      expect(w.book).to eq book
      expect(w.books).to eq [book]
    end
  end

  describe "normal ruby methods" do
    it "ruby methods can be defined on the World class, or any included modules" do
      w = World.new
      expect(w.method_on_world).to eq w
      expect(w.method_on_book_module).to eq w
    end
  end
end
