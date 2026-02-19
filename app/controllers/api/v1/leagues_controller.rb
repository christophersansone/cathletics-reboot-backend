module Api
  module V1
    class LeaguesController < BaseController
      before_action :set_season
      before_action :set_league, only: [:show, :update, :destroy]

      def index
        leagues = @season.leagues
        render_models leagues
      end

      def show
        render_model @league
      end

      def create
        league = @season.leagues.new(league_params)
        authorize! :create, league

        if league.save
          render_model league, status: :created
        else
          render_errors league
        end
      end

      def update
        authorize! :update, @league

        if @league.update(league_params)
          render_model @league
        else
          render_errors @league
        end
      end

      def destroy
        authorize! :destroy, @league
        @league.mark_as_deleted!
        head :no_content
      end

      private

      def set_season
        @season = Season.find(params[:season_id])
      end

      def set_league
        @league = @season.leagues.find(params[:id])
      end

      def league_params
        params.require(:data).require(:attributes).permit(
          :name, :gender, :min_grade, :max_grade,
          :min_age, :max_age, :age_cutoff_date, :capacity
        )
      end
    end
  end
end
