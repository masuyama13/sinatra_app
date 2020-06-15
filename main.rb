# frozen_string_literal: true

require "sinatra"
require "sinatra/reloader"
require "json"

class Memo
  attr_reader :id, :title, :content

  def initialize(id, title, content)
    @id = id
    @title = title
    @content = content
  end

  def self.create(hash_data, post_data)
    id =
      if hash_data["memos"].size == 0
        1
      else
        hash_data["memos"][-1]["id"] + 1
      end
    ary = post_data.split("\s")
    title = ary[0]
    ary.delete_at(0)
    content = ary.join("<br>")
    Memo.new(id, title, content)
  end

  def self.create_with_id(id, post_data)
    ary = post_data.split("\s")
    title = ary[0]
    ary.delete_at(0)
    content = ary.join("<br>")
    Memo.new(id, title, content)
  end

  def self.refer(item)
    id = item["id"]
    title = item["title"]
    content = item["content"]
    Memo.new(id, title, content)
  end

  def to_hash
    { "id" => id, "title" => title, "content" => content }
  end
end

enable :method_override
get "/" do
  File.open("memos.json") { |f| @hash_data = JSON.load(f)["memos"] }
  erb :index
end

get "/new_memo" do
  erb :form
end

post "/memos" do
  hash_data = File.open("memos.json") { |f| JSON.load(f) }
  memo = Memo.create(hash_data, params[:text])
  new_items = hash_data["memos"].push(memo.to_hash)
  new_hash = { "memos" => new_items }
  File.open("memos.json", "w") { |f| JSON.dump(new_hash, f) }
  redirect "/"
end

get "/:id" do |id|
  File.open("memos.json") do |f|
    target =
      JSON.load(f)["memos"].find { |item| item["id"] == id.to_i }
    memo = Memo.refer(target)
    @id = memo.id
    @title = memo.title
    @content = memo.content
  end
  erb :memo
end

delete "/:id" do |id|
  hash_data = File.open("memos.json") { |f| JSON.load(f) }
  new_items = hash_data["memos"].delete_if { |item| item["id"] == id.to_i }
  new_hash = { "memos" => new_items }
  File.open("memos.json", "w") { |f| JSON.dump(new_hash, f) }
  redirect "/"
end

get "/:id/edit" do |id|
  File.open("memos.json") do |f|
    target =
      JSON.load(f)["memos"].find { |item| item["id"] == id.to_i }
    memo = Memo.refer(target)
    @edit_text = memo.title + "\n" + "\n" + memo.content.gsub("<br>", "\n")
  end
  erb :edit
end

patch "/:id/edit" do |id|
  hash_data = File.open("memos.json") { |f| JSON.load(f) }
  memo = Memo.create_with_id(id.to_i, params[:text])
  target =
    hash_data["memos"].find_index { |item| item["id"] == id.to_i }
  hash_data["memos"][target] = memo.to_hash
  File.open("memos.json", "w") { |f| JSON.dump(hash_data, f) }
  redirect "/"
end
