describe "proxy deposit and transfers routing", type: :routing do
  routes { Sufia::Engine.routes }

  it "lists transfers" do
    expect(transfers_path).to eq '/dashboard/transfers'
    expect(get: '/dashboard/transfers').to route_to(controller: 'sufia/transfers', action: 'index')
  end

  it "creates a transfer" do
    expect(work_transfers_path('7')).to eq '/works/7/transfers'
    expect(post: '/works/7/transfers').to route_to(controller: 'sufia/transfers', action: 'create', id: '7')
  end

  it "shows a form for a new transfer" do
    expect(new_work_transfer_path('7')).to eq '/works/7/transfers/new'
    expect(get: '/works/7/transfers/new').to route_to(controller: 'sufia/transfers', action: 'new', id: '7')
  end

  it "cancels a transfer" do
    expect(transfer_path('7')).to eq '/dashboard/transfers/7'
    expect(delete: '/dashboard/transfers/7').to route_to(controller: 'sufia/transfers', action: 'destroy', id: '7')
  end

  it "accepts a transfers" do
    expect(accept_transfer_path('7')).to eq '/dashboard/transfers/7/accept'
    expect(put: '/dashboard/transfers/7/accept').to route_to(controller: 'sufia/transfers', action: 'accept', id: '7')
  end

  it "rejects a transfer" do
    expect(reject_transfer_path('7')).to eq '/dashboard/transfers/7/reject'
    expect(put: '/dashboard/transfers/7/reject').to route_to(controller: 'sufia/transfers', action: 'reject', id: '7')
  end

  it "adds a proxy depositor" do
    expect(user_depositors_path('xxx666@example-dot-org')).to eq '/users/xxx666@example-dot-org/depositors'
    expect(post: '/users/xxx666@example-dot-org/depositors').to route_to(controller: 'sufia/depositors', action: 'create', user_id: 'xxx666@example-dot-org')
  end

  it "removes a proxy depositor" do
    expect(user_depositor_path('xxx666', '33')).to eq '/users/xxx666/depositors/33'
    expect(delete: '/users/xxx666/depositors/33').to route_to(controller: 'sufia/depositors', action: 'destroy', user_id: 'xxx666', id: '33')
  end
end
