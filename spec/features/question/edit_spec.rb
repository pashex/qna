require 'rails_helper'

feature 'User can edit question', %q{
  In order to correct mistakes
  As an author of question
  I'd like to be able to edit a question
} do

  given(:user) { create :user }
  given!(:question) { create :question, user: user }
  given!(:another_question) { create :question }

  describe 'Authenticated user', js: true do
    background { login(user) }

    describe 'edits his question' do
      before do
        visit question_path(question)
        click_on 'Edit question'
      end

      scenario 'correctly' do
        within '.question' do
          fill_in 'Title', with: 'Edited Title'
          fill_in 'Body', with: 'Edited Body'
          click_on 'Save'

          expect(page).not_to have_content question.title
          expect(page).not_to have_content question.body
          expect(page).to have_content 'Edited Title'
          expect(page).to have_content 'Edited Body'
          expect(page).not_to have_content 'textarea'
        end
      end

      scenario 'adding attached files' do
        within '.question' do
          expect(page).to have_no_content 'rails_helper.rb'
          expect(page).to have_no_content 'spec_helper.rb'

          attach_file 'Files', ["#{Rails.root}/spec/rails_helper.rb", "#{Rails.root}/spec/spec_helper.rb"]
          click_on 'Save'

          expect(page).to have_content 'rails_helper.rb'
          expect(page).to have_content 'spec_helper.rb'
        end
      end

      context 'when question has files' do
        background do
          question.files.attach(io: File.open("#{Rails.root}/spec/rails_helper.rb"), filename: 'rails_helper.rb')
          visit question_path(question)
          click_on 'Edit question'
        end

        scenario 'adding attached files to question with files' do
          within '.question' do
            expect(page).to have_content 'rails_helper.rb'
            expect(page).to have_no_content 'spec_helper.rb'

            attach_file 'Files', ["#{Rails.root}/spec/spec_helper.rb"]
            click_on 'Save'

            expect(page).to have_content 'rails_helper.rb'
            expect(page).to have_content 'spec_helper.rb'
          end
        end
      end

      scenario 'with errors' do
        within '.question' do
          fill_in 'Body', with: ''
          click_on 'Save'

          expect(page).to have_content question.body
          expect(page).to have_content "Body can't be blank"
        end
      end
    end

    scenario "tries to edit another user's question" do
      visit question_path(another_question)
      within '.question' do
        expect(page).to have_no_link "Edit question"
      end
    end
  end

  scenario 'Unauthenticated user cannot edit questions' do
    visit question_path(question)
    within '.question' do
      expect(page).to have_no_link "Edit question"
    end
  end

end
