# frozen_string_literal: true

require 'rails_helper'

describe Admin::ReportsController do
  render_views

  let(:user) { Fabricate(:user, role: UserRole.find_by(name: 'Admin')) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET #index' do
    it 'returns http success with no filters' do
      specified = Fabricate(:report, action_taken_at: nil, comment: 'First report')
      other = Fabricate(:report, action_taken_at: Time.now.utc, comment: 'Second report')

      get :index

      expect(response).to have_http_status(200)
      expect(response.body)
        .to include(specified.comment)
        .and not_include(other.comment)
    end

    it 'returns http success with resolved filter' do
      specified = Fabricate(:report, action_taken_at: Time.now.utc, comment: 'First report')
      other = Fabricate(:report, action_taken_at: nil, comment: 'Second report')

      get :index, params: { resolved: '1' }

      expect(response).to have_http_status(200)
      expect(response.body)
        .to include(specified.comment)
        .and not_include(other.comment)
    end
  end

  describe 'GET #show' do
    it 'renders report' do
      report = Fabricate(:report, comment: 'A big problem')

      get :show, params: { id: report }

      expect(response).to have_http_status(200)
      expect(response.body)
        .to include(report.comment)
    end
  end

  describe 'POST #resolve' do
    it 'resolves the report' do
      report = Fabricate(:report)

      put :resolve, params: { id: report }
      expect(response).to redirect_to(admin_reports_path)
      report.reload
      expect(report.action_taken_by_account).to eq user.account
      expect(report.action_taken?).to be true
      expect(last_action_log.target).to eq(report)
    end
  end

  describe 'POST #reopen' do
    it 'reopens the report' do
      report = Fabricate(:report, action_taken_at: 3.days.ago)

      put :reopen, params: { id: report }
      expect(response).to redirect_to(admin_report_path(report))
      report.reload
      expect(report.action_taken_by_account).to be_nil
      expect(report.action_taken?).to be false
      expect(last_action_log.target).to eq(report)
    end
  end

  describe 'POST #assign_to_self' do
    it 'reopens the report' do
      report = Fabricate(:report)

      put :assign_to_self, params: { id: report }
      expect(response).to redirect_to(admin_report_path(report))
      report.reload
      expect(report.assigned_account).to eq user.account
      expect(last_action_log.target).to eq(report)
    end
  end

  describe 'POST #unassign' do
    it 'reopens the report' do
      report = Fabricate(:report, assigned_account_id: Account.last.id)

      put :unassign, params: { id: report }
      expect(response).to redirect_to(admin_report_path(report))
      report.reload
      expect(report.assigned_account).to be_nil
      expect(last_action_log.target).to eq(report)
    end
  end

  private

  def last_action_log
    Admin::ActionLog.last
  end
end
