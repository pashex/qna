App.answers = App.cable.subscriptions.create channel: "AnswersChannel", question_id: gon.question_id,
  connected: ->

  disconnected: ->

  received: (data) ->
    console.log('received:', data)
    if data.user_id != gon.user_id
      $(".answers").append App.utils.render("answer", data)
