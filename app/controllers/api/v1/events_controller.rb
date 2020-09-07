class Api::V1::EventsController < ApplicationController
  
  before_action :authenticate_user, only: 
    [:create, :update, :destroy, :receive_demand ]

  # GET '/api/v1/events
  def index 
    upcoming_itinaries = Itinary.where('date >?', Date.today-1)
    events =   Event.includes(:user, :itinary).where(itinary: [upcoming_itinaries])
      .to_json( include: [ 
          user: {only: [:email]},
          itinary: {only: [:date, :start, :end, :distance, :start_gps, :end_gps ]}
          ]
      )
    #expires_in 3.hours, public: true
    #fresh_when(events.to_json, public: true)
    if stale?(events)
      render json: events
    end
  end

  # GET '/api/v1/events/:id'
  def show
    event = Event.find(params[:id])
    return render json: event.to_json(
      include: [
        user: {only: :email},
        itinary: {only: [:date, :start, :end]},
      ]
    )
  end

  # POST '/api/v1/events'
  def create   
    # if params[:event][:itinary_attributes][:start_gps]
    #   params[:event][:itinary_attributes][:start_gps] = params[:event][:itinary_attributes][:start_gps][0].split(',')
    #   params[:event][:itinary_attributes][:end_gps] = params[:event][:itinary_attributes][:end_gps][0].split(',')
    # end
    #params.permit!
    event_params = params.require(:event).permit( 
        :user,
        :directCLurl,
        :publicID,
        :comment,
        itinary_attributes: [:date, :start, :end, :distance, start_gps: [], end_gps: []],
        participants: [:email, :notif, :id, :ptoken],
      ) 
    # !! permitting an array must be at the end !!
    
    event = Event.new(event_params)
    event.user = current_user

    if !event.save
      return render json: event.errors.full_messages, status: :unprocessable_entity
    end

    if event.participants
      event.participants.each do |participant|
        # 'jsonb' format => participant['email'], not symbol :email
        participant['notif'] = true
        EventMailer.invitation(participant['email'], event.id)
        .deliver_later
      end
      event.save
    end
    # !! had to remove all the fields from ':itinary', and put 'only at the end!!
    return render json:  event.to_json(include: [ :itinary, user:{only: :email}]), status: 201
  end

  #  PATCH 'api/v1/events/:id'
  def update
    event = Event.find(params[:id]) 
    return render json: {status: 401} if event.user != current_user
    
    # if we update direct link, then first remove from CL if one exists
    if event_params[:directCLurl] && event.directCLurl
      RemoveDirectLink.perform_later(event.publicID) 
    end

    # to accept an array, we need to separate between the ','
    # if params[:event][:itinary_attributes][:start_gps]
    # params[:event][:itinary_attributes][:start_gps] = params[:event][:itinary_attributes][:start_gps][0].split(',')
    # params[:event][:itinary_attributes][:end_gps] = params[:event][:itinary_attributes][:end_gps][0].split(',')
    # end
    
    #params.permit!
    event_params = params.require(:event).permit( 
        :user,
        :directCLurl,
        :publicID,
        :comment,
        itinary_attributes: [:date, :start, :end, :distance, start_gps: [], end_gps: []],
        participants: [:email, :notif, :id, :ptoken],
      ) 
      
    if event.update(event_params)
      if event.participants
        event.participants.each do |participant|
          # 'jsonb' format => participant['email'], not :email
          participant['notif'] = true
          EventMailer.invitation(participant['email'], event.id)
          .deliver_later
        end
        event.save
      end
      return render json: event.to_json(include: [ :itinary, user:{only: :email}]), status: 201
    else
      return render json: {errors: event.errors.full_messages},
        status: :unprocessable_entity
    end
  end

  # DELETE '/api/v1/events/:id'
  def destroy
    event = Event.find(params[:id])   
    return render json: { status: 401 } if event.user != current_user
    #async Active_Job  for Cloudinary
    RemoveDirectLink.perform_later(event.publicID) if event.publicID
    event.itinary.destroy
    event.destroy
    return render json: {status: 200}
  end

  
  # POST '/api/v1/pushDemand'
  # send mail to owner of an event for user to join
  def receive_demand
    token = SecureRandom.urlsafe_base64.to_s
    event = Event.find(params[:event][:id])
    itinary_id = event.itinary.id
    owner_email = params[:owner]
    event.participants=[] if event.participants == nil
    event.participants << {email: params[:user][:email], notif: false, ptoken: token}
    event.save
    EventMailer.demand(current_user.email , owner_email, itinary_id, token )
      .deliver_later
    
    return render status: 200
  end

  
  # GET 'api/v1/confirmDemand/?name=XXX?user=YYY?ptoken=ZZZ'
  # token sent from link in mail for owner to accept user
  def confirm_demand
    owner = params[:name]
    itinary = Itinary.find(params[:itinary])
    events = Event.includes(:user).where(users: {email: owner})
    events.each do |event|
      return if !event.participants
      event.participants.each do |p|
        if p['ptoken'] && p['ptoken']== params[:ptoken]
          p['notif']=true
          p['ptoken'] = ''
          event.save
        end
      end
    end
    user = params[:user]
    UserMailer.accept(user, owner, itinary.id).deliver_later
    return true
  end

  private
    def event_params
      params.require(:event).permit( 
        :user,
        :directCLurl,
        :publicID,
        :comment,
        itinary_attributes: [:date, :start, :end, :distance, start_gps: [], end_gps: []],
        participants: [:email, :notif, :id, :ptoken]
      ) 
    end
    
end
