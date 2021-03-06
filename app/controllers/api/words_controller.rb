require 'exceptions'
require 'word_request_cache'

class Api::WordsController < ApplicationController
  include Exceptions

  def index
    limit_request_rate
    cached_query_result = Word.find_by(word: params[:query])

    # Handle already looked up words
    if cached_query_result
      render json: [cached_query_result.word]
      return
    end

    get_query_results

    # Handle no results
    unless @query_results['totalResults'] > 0
      render :no_search_result_error, status: 404
      return
    end

    render :index
  rescue Exceptions::ExternalApiError
    WordRequestCache.enqueue_query(params[:query], current_user)
    render :wordnik_down_error, status: 503
  end

  def show
    limit_request_rate
    @word = Word.find_by_word(params[:word])

    # Handle no results
    unless @word
      render :no_show_result_error, status: 404
      return
    end

    render :show
  rescue Exceptions::ExternalApiError
    WordRequestCache.enqueue_query(params[:word], current_user)
    render :wordnik_down_error, status: 503
  end

  private

  def get_query_results
    @query_results = Word.query_wordnik(params[:query])
  end
end
