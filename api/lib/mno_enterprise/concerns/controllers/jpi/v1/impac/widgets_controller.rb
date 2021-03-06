module MnoEnterprise::Concerns::Controllers::Jpi::V1::Impac::WidgetsController
  extend ActiveSupport::Concern

  #==================================================================
  # Included methods
  #==================================================================
  # 'included do' causes the included code to be evaluated in the
  # context where it is included rather than being executed in the module's context
  included do
    respond_to :json
  end

  #==================================================================
  # Instance methods
  #==================================================================
  # GET /mnoe/jpi/v1/impac/organizations/:organization_id/widgets
  #  -> GET /api/mnoe/v1/organizations/:id/widgets
  def index
    render_not_found('organization') unless parent_organization
    @widgets = parent_organization.widgets
  end

  # POST /mnoe/jpi/v1/impac/dashboards/:id/widgets
  #  -> POST /api/mnoe/v1/dashboards/:id/widgets
  def create
    if widgets
      if @widget = widgets.create(widget_create_params)
        MnoEnterprise::EventLogger.info('widget_create', current_user.id, 'Widget Creation', widget)
        @nocontent = true # no data fetch from Connec!
        render 'show'
      else
        render_bad_request('create widget', @widget.errors)
      end
    else
      render_not_found('widget')
    end
  end

  # PUT /mnoe/jpi/v1/impac/widgets/:id
  #   -> PUT /api/mnoe/v1/widgets/:id
  def update
    if widget.update(widget_update_params)
      MnoEnterprise::EventLogger.info('widget_update', current_user.id, 'Widget Update', widget, {widget_action: params[:widget]})
      @nocontent = !params['metadata']
      render 'show'
    else
      render_bad_request('update widget', @widget.errors)
    end
  end

  # DELETE /mnoe/jpi/v1/impac/widgets/:id
  #   -> DELETE /api/mnoe/v1/widgets/:id
  def destroy
    if widget.destroy
      MnoEnterprise::EventLogger.info('widget_delete', current_user.id, 'Widget Deletion', widget)
      head status: :ok
    else
      render_bad_request('destroy widget', 'Unable to destroy widget')
    end
  end


  #=================================================
  # Private methods
  #=================================================
  private

    def widget
      @widget ||= MnoEnterprise::Impac::Widget.find(params[:id])
    end

    def widgets
      @widgets ||= MnoEnterprise::Impac::Dashboard.find(params[:dashboard_id]).widgets
    end

    def widget_create_params
      params.require(:widget).permit(:endpoint, :name, :width).tap do |whitelisted|
        whitelisted[:settings] = params[:widget][:metadata] || {}
        # TODO: remove when mnohub migrated to new model
        whitelisted[:widget_category] = params[:widget][:endpoint]
      end
      .except(:metadata)
    end

    def widget_update_params
      params.require(:widget).permit(:name, :width).tap do |whitelisted|
        whitelisted[:settings] = params[:widget][:metadata] || {}
      end
      .except(:metadata)
    end
end
