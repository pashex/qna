require 'rails_helper'

RSpec.describe AnswersController, type: :controller do
  let(:question) { create :question }
  let(:user) { create :user }

  describe 'POST #create' do
    subject { post :create, params: { question_id: question.id, answer: attributes_for(:answer) }, format: :js }
    let(:last_answer) { Answer.order(:created_at).last }

    describe 'by authenticated user' do
      before { login(user) }

      context 'with valid params' do
        it 'should create new answer for question' do
          expect { subject }.to change { question.answers.count }.by(1)
        end
        it { should render_template(:create) }

        it 'should broadcast new answer to channel' do
          expect { subject }.to have_broadcasted_to("answers-#{question.id}").with(last_answer)
        end
      end

      context 'with attached files' do
        it 'should attach files to answer' do
          post :create, params: { question_id: question.id, answer: { body: 'Body', files: [fixture_file_upload('spec/spec_helper.rb')]}, format: :js }
          expect(last_answer.files).to be_attached
        end
      end

      context 'with links' do
        context 'where links is valid' do
          it 'should add links to answer' do
            post :create, params: { question_id: question.id, answer: { body: 'Body', links_attributes: { 0 => { name: 'Google', url: 'https://google.com' }, 1 => { name: 'Yandex', url: 'https://yandex.ru' } } }, format: :js }
            expect(last_answer.links.pluck(:name).sort).to eq ['Google', 'Yandex']
            expect(last_answer.links.pluck(:url).sort).to eq ['https://google.com', 'https://yandex.ru']
          end
        end
        context 'where links is not valid' do
          subject do
            post :create, params: { question_id: question.id, answer: { body: 'Body', links_attributes: { 0 => { url: 'https://google.com' } } }, format: :js }
          end

          it 'should not create new answer' do
            expect { subject }.not_to change { Answer.count }
          end

          it 'should not broadcast to channel' do
            expect { subject }.not_to have_broadcasted_to("answers-#{question.id}")
          end

          it { should render_template(:create) }
        end
      end

      context 'with invalid params' do
        subject { post :create, params: { question_id: question.id, answer: attributes_for(:answer, :invalid) }, format: :js }

        it 'should not create new answer' do
          expect { subject }.not_to change { Answer.count }
        end

        it 'should not broadcast to channel' do
          expect { subject }.not_to have_broadcasted_to("answers-#{question.id}")
        end

        it { should render_template(:create) }
      end
    end

    describe 'by unauthenticated user' do
      it 'should not create new answer' do
        expect { subject }.not_to change { Answer.count }
      end

      it 'should not broadcast to channel' do
        expect { subject }.not_to have_broadcasted_to("answers-#{question.id}")
      end

      it 'should return unauthorized status' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH #update' do
    it_behaves_like 'update resource' do
      let!(:resource) { create :answer, question: question, user: user  }
      let(:update_attributes) { { body: 'Edited answer'} }
      let(:invalid_attributes) { { body: ' '} }
    end
  end

  describe 'PATCH #make_best' do
    let(:question) { create :question, user: user }
    let!(:answer) { create :answer, question: question }
    subject { patch :make_best, params: { id: answer }, format: :js }

    describe 'by authenticated user' do
      before { login(user) }

      context 'answer for his question' do

        it 'should make answer the best' do
          subject
          expect(answer.reload).to be_best
        end

        it { should render_template(:make_best) }
      end

      context "answer for other user's question" do
        let(:another_question) { create :question }
        let(:answer) { create :answer, question: another_question }

        before { patch :make_best, params: { id: answer }, format: :js }

        it 'should not make answer the best' do
          expect(answer.reload).not_to be_best
        end

        it 'should return forbidden status' do
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe 'by unauthenticated user' do
      before { subject }

      it 'should not make any answers to the best' do
        expect(answer.reload).not_to be_best
      end

      it 'should return unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:question) { create :question }
    let!(:answer) { create :answer, question: question, user: user }
    let!(:another_answer) { create :answer, question: question }

    subject { delete :destroy, params: { question_id: answer.question, id: answer }, format: :js }

    describe 'by authenticated user' do
      before { login(user) }

      describe 'for own answer' do
        it 'should destroy answer' do
          expect { subject }.to change { Answer.count }.by(-1)
          expect(Answer).not_to exist(answer.id)
        end

        it { should render_template(:destroy) }
      end

      describe 'for another`s answer' do
        subject { delete :destroy, params: { question_id: another_answer.question, id: another_answer }, format: :js }

        it 'should not delete answer' do
          expect { subject }.not_to change { Answer.count }
          expect(Answer).to exist(another_answer.id)
        end

        it 'should return forbidden status' do
          subject
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe 'by unauthenticated user' do
      it 'should not delete any answer' do
        expect { subject }.not_to change { Answer.count }
        expect(Answer).to exist(answer.id)
      end

      it 'should return unauthorized status' do
        subject
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

end
