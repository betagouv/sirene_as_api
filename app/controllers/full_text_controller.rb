require 'sunspot'

class FullTextController < ApplicationController
  @filter_nature_prospection = true

  def show
    page = params[:page] || 1
    @number_of_searches = 0
    spellcheck_search(params[:text], page)
  end

  def spellcheck_search(query, page)
    search = search_with_solr_options(query, page)
    results = search.results

    if !results.blank?
      results_payload = {
        total_results: search.total,
        total_pages: results.total_pages,
        per_page: results.per_page,
        page: page,
        etablissement: results
      }
      render json: results_payload, status: 200
    else
      spellchecked_query = search.spellcheck_collation
      if spellchecked_query.nil? || @number_of_searches >= 2
        render json: { message: 'no results found' }, status: 404
      else
        @number_of_searches += 1
        spellcheck_search(spellchecked_query, page)
      end
    end
  end

  def search_with_solr_options(keyword, page)
    search = Etablissement.search do
      fulltext keyword
      facet :activite_principale
      with(:activite_principale, params[:activite_principale]) if params[:activite_principale].present?
      facet :code_postal
      with(:code_postal, params[:code_postal]) if params[:code_postal].present?
      facet :is_ess
      with(:is_ess, params[:is_ess]) if params[:is_ess].present?
      with_filter_entrepreneur_individuel if params[:is_entrepreneur_individuel].present?
      without(:nature_mise_a_jour, %w[O E])
      without(:statut_prospection, 'O')

      spellcheck :count => 5

      # without(:nature_mise_a_jour).any_of(%w[O E])
      # without(:statut_prospection).any_of('O')
      # filter_nature_prospection if @filter_nature_prospection
      paginate page: page, per_page: 10
    end
    search
  end

  # Scoping
  def filter_nature_prospection
    without(:nature_mise_a_jour).any_of(%w[O E])
    without(:statut_prospection, 'O')
  end
end

def with_filter_entrepreneur_individuel
  if params[:is_entrepreneur_individuel] == 'yes'
    with(:nature_entrepreneur_individuel, ('1'..'9').to_a)
  elsif params[:is_entrepreneur_individuel] == 'no'
    without(:nature_entrepreneur_individuel, ('1'..'9').to_a)
  end
end

# Modified Sunspot classes for making Spellcheck work.
module Sunspot::Search
  class StandardSearch
    def spellcheck_suggestion_for(term)
      if spellcheck_suggestions.nil? || spellcheck_suggestions[term].nil?
        return nil
      end
      spellcheck_suggestions[term]['suggestion'].sort_by do |suggestion|
        suggestion['freq']
      end.last['word']
    end

    def spellcheck_collation(*terms)
      if solr_spellcheck['suggestions'] && solr_spellcheck['suggestions'].length > 0
        collation = terms.join(" ").dup if terms

        if terms.length > 0
          terms.each do |term|
            if (spellcheck_suggestions[term]||{})['origFreq'] == 0
              collation[term] = spellcheck_suggestion_for(term)
            end
          end
        end

        if terms.length == 0
          collation = solr_spellcheck['collations'][-1]
        end

        collation
      else
        nil
      end
    end
  end
end
