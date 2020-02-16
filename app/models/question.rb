class Question < ApplicationRecord
  has_many :answers, -> { order(best: :desc) }, dependent: :destroy
  has_many :links, as: :linkable, dependent: :destroy
  has_one :award, dependent: :destroy
  belongs_to :user

  has_many_attached :files
  accepts_nested_attributes_for :links, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :award, reject_if: proc { |attributes| attributes['name'].blank? }

  validates :title, :body, presence: true
  validates :title, uniqueness: true

  def best_answer
    answers.find_by(best: true)
  end
end
