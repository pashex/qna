require 'rails_helper'

feature 'User can sign in with omniauth',%q{
  In order to ask questions
  As an unauthenticated user
  I'd like to be able to sign in with omniauth
} do

  background { visit new_user_session_path }

  describe "Sign in with Github" do
    background { mock_auth_hash(:github) }

    scenario "user can sign in with Github account" do
      click_on "Sign in with GitHub"
      expect(page).to have_content('Successfully authenticated from Github account')
      expect(page).to have_content("mockuser@email.com")
      expect(page).to have_content("Log out")
    end

    scenario "can handle authentication error" do
      OmniAuth.config.mock_auth[:github] = :invalid_credentials
      click_on "Sign in with GitHub"
      expect(page).to have_content('Could not authenticate you from GitHub')
    end
  end

  describe "Sign in with VK" do
    background { mock_auth_hash(:vkontakte) }

    context 'when VK account has email' do
      scenario "user can sign in with VK account" do
        click_on "Sign in with Vkontakte"
        expect(page).to have_content('Successfully authenticated from Vkontakte account')
        expect(page).to have_content("mockuser@email.com")
        expect(page).to have_content("Log out")
      end

      scenario "can handle authentication error" do
        OmniAuth.config.mock_auth[:vkontakte] = :invalid_credentials
        click_on "Sign in with Vkontakte"
        expect(page).to have_content('Could not authenticate you from Vkontakte')
      end
    end

    context 'when VK account has no email' do
      background do
        OmniAuth.config.mock_auth[:vkontakte]['info']['email'] = ''
      end

      context "user has not filled email manually" do
        context 'user fills valid email' do
          background do
            clear_emails
            click_on "Sign in with Vkontakte"
            fill_in 'Email', with: 'user@email.com'
            click_on 'Set email'
          end

          scenario "user does not sign in and view message about confirmation link" do
            expect(page).to have_content('A message with a confirmation link has been sent to your email address. Please follow the link to activate your account')
            expect(page).not_to have_content("mockuser@email.com")
            expect(page).not_to have_content("Log out")
            expect(page).not_to have_link("Sign in with Vkontakte")
          end

          scenario "user receive confirmation email in his mailbox" do
            open_email('user@email.com')
            expect(current_email).to be_present
            expect(current_email).to have_link 'Confirm my account'
          end

          scenario "user clicks confirmation link in email after set email" do
            open_email('user@email.com')
            current_email.click_link 'Confirm my account'
            expect(page).to have_content 'Your email address has been successfully confirmed'
          end

          scenario "user login with after confirmation new email" do
            open_email('user@email.com')
            current_email.click_link 'Confirm my account'
            click_on "Sign in with Vkontakte"
            expect(page).to have_content('Successfully authenticated from Vkontakte account')
            expect(page).to have_content("user@email.com")
            expect(page).to have_content("Log out")
          end
        end

        scenario "user fill invalid email in field" do
          click_on "Sign in with Vkontakte"
          fill_in 'Email', with: ' '
          click_on 'Set email'
          expect(page).to have_content("Email can't be blank")
          expect(page).not_to have_content('A message with a confirmation link has been sent to your email address. Please follow the link to activate your account')
        end
      end

      context "user has filled email manually earlier" do
        given(:user) { create :user }
        background do
          user.authorizations.create!(provider: 'vkontakte', uid: OmniAuth.config.mock_auth[:vkontakte]['uid'])
        end

        context "when user has confirmed his email" do
          scenario "user can sign in with VK account" do
            click_on "Sign in with Vkontakte"
            expect(page).to have_content('Successfully authenticated from Vkontakte account')
            expect(page).to have_content(user.email)
            expect(page).to have_content("Log out")
          end
        end

        context "when user hasn't confirmed his email earlier" do
          background { user.update!(confirmed_at: nil) }

          scenario "user doesn't sign in and view 'need to confirm' message" do
            click_on "Sign in with Vkontakte"
            expect(page).not_to have_content('Successfully authenticated from Vkontakte account')
            expect(page).not_to have_content(user.email)
            expect(page).not_to have_content("Log out")
            expect(page).to have_content('You have to confirm your email address before continuing')
          end
        end
      end
    end
  end

end
