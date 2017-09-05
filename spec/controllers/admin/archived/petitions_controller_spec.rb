require 'rails_helper'

RSpec.describe Admin::Archived::PetitionsController, type: :controller, admin: true do
  before do
    FactoryGirl.create(:parliament, :archived)
  end

  context "when not logged in" do
    describe "GET /admin/archived/petitions" do
      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end

    describe "GET /admin/archived/petitions/:id" do
      it "redirects to the login page" do
        get :show, id: "100000"
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/login")
      end
    end
  end

  context "when logged in as a moderator but need to reset password" do
    let(:user) { FactoryGirl.create(:moderator_user, force_password_reset: true) }
    before { login_as(user) }

    describe "GET /admin/archived/petitions" do
      it "redirects to the edit profile page" do
        get :index
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end

    describe "GET /admin/archived/petitions/:id" do
      it "redirects to the edit profile page" do
        get :show, id: "100000"
        expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/profile/#{user.id}/edit")
      end
    end
  end

  context "when logged in as a moderator" do
    let(:user) { FactoryGirl.create(:moderator_user) }
    before { login_as(user) }

    describe "GET /admin/archived/petitions" do
      context "when making a HTML request" do
        before { get :index }

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :index template" do
          expect(response).to render_template("admin/archived/petitions/index")
        end
      end

      context "when making a CSV request" do
        before { get :index, format: "csv" }

        it "returns a CSV file" do
          expect(response.content_type).to eq("text/csv")
        end

        it "doesn't set the content length" do
          expect(response.content_length).to be_nil
        end

        it "sets the streaming headers" do
          expect(response["Cache-Control"]).to match(/no-cache/)
          expect(response["X-Accel-Buffering"]).to eq("no")
        end

        it "sets the content disposition" do
          expect(response['Content-Disposition']).to match(/attachment; filename=all-petitions-\d{14}\.csv/)
        end
      end

      context "when searching by id" do
        before { get :index, q: "100000" }

        it "redirects to the admin petition page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin/archived/petitions/100000")
        end
      end
    end

    describe "GET /admin/archived/petitions/:id" do
      context "when the petition doesn't exist" do
        before { get :show, id: "999999" }

        it "redirects to the admin dashboard page" do
          expect(response).to redirect_to("https://moderate.petition.parliament.uk/admin")
        end

        it "sets the flash alert message" do
          expect(flash[:alert]).to eq("Sorry, we couldn't find petition 999999")
        end
      end

      context "when the petition exists" do
        let!(:petition) { FactoryGirl.create(:archived_petition) }

        before { get :show, id: petition.to_param }

        it "returns 200 OK" do
          expect(response).to have_http_status(:ok)
        end

        it "renders the :show template" do
          expect(response).to render_template("admin/archived/petitions/show")
        end
      end
    end
  end
end