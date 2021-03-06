require 'rails_helper'

feature 'User can edit answer for question', %q{
  In order to correct mistakes
  As an author of answer
  I'd like to be able to edit an answer for question
} do

  given(:user) { create :user }
  given(:question) { create :question }
  given!(:answer) { create :answer, question: question, user: user }
  given!(:another_answer) { create :answer, question: question }

  describe 'Authenticated user', js: true do
    background do
      login(user)
      visit question_path(question)
    end

    scenario 'edits his answer for the question' do
      within "#answer-#{answer.id}" do
        click_on 'Edit answer'
        fill_in 'Body', with: 'Edited answer'
        click_on 'Save'

        expect(page).not_to have_content answer.body
        expect(page).to have_content 'Edited answer'
        expect(page).to have_no_selector 'textarea#answer-body'
      end
    end

    scenario 'edits his answer with adding attached files' do
      within "#answer-#{answer.id}" do
        expect(page).to have_no_content 'rails_helper.rb'
        expect(page).to have_no_content 'spec_helper.rb'

        click_on 'Edit answer'
        attach_file 'Files', ["#{Rails.root}/spec/rails_helper.rb", "#{Rails.root}/spec/spec_helper.rb"]
        click_on 'Save'

        expect(page).to have_content 'rails_helper.rb'
        expect(page).to have_content 'spec_helper.rb'
      end
    end

    context 'when answer has files' do
      background do
        answer.files.attach(io: File.open("#{Rails.root}/spec/rails_helper.rb"), filename: 'rails_helper.rb')
        visit question_path(question)
      end

      scenario 'edits his answer adding attached files' do
        within "#answer-#{answer.id}" do
          expect(page).to have_content 'rails_helper.rb'
          expect(page).to have_no_content 'spec_helper.rb'

          click_on 'Edit answer'
          attach_file 'Files', ["#{Rails.root}/spec/spec_helper.rb"]
          click_on 'Save'

          expect(page).to have_content 'rails_helper.rb'
          expect(page).to have_content 'spec_helper.rb'
        end
      end
    end

    scenario 'edit his answer with errors' do
      within "#answer-#{answer.id}" do
        click_on 'Edit answer'
        fill_in 'Body', with: ''
        click_on 'Save'

        expect(page).to have_content answer.body
        expect(page).to have_content "Body can't be blank"
        expect(page).to have_selector 'textarea'
      end
    end

    scenario "tries to edit another user's answer" do
      within "#answer-#{another_answer.id}" do
        expect(page).not_to have_content "Edit answer"
      end
    end
  end

  scenario 'Unauthenticated user cannot edit answers' do
    visit question_path(question)
    expect(page).not_to have_content "Edit answer"
  end

end
