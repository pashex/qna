# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).on 'turbolinks:load', ->
  $('body').on 'ajax:success', '.vote-link', (event) ->
    vote = event.detail[0].vote
    rating = event.detail[0].rating
    message = if vote.status is 'like' then 'You like it!' else 'You dislike it!'
    vote_block = $("#votable-#{vote.votable_type.toLowerCase()}-#{vote.votable_id}")
    vote_block.find(".vote").html(message)
    vote_block.find(".vote-rating").html("Rating: #{rating}")

  voteLink = (name, status, vote) ->
    "<a data-type='json' class='vote-link' data-remote='true' rel='nofollow' data-method='post' href='/votes?status=#{status}&amp;votable_id=#{vote.votable_id}&amp;votable_type=#{vote.votable_type}' >#{name}</a>"

  $('body').on 'ajax:success', '.cancel-vote-link', (event) ->
    vote = event.detail[0].vote
    rating = event.detail[0].rating
    vote_block = $("#votable-#{vote.votable_type.toLowerCase()}-#{vote.votable_id}")
    vote_block.find(".vote").html(voteLink('Like', 'like', vote) + voteLink('Dislike', 'dislike', vote))
    vote_block.find(".vote-rating").html("Rating: #{rating}")
