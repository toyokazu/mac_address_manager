require 'test_helper'

class MacAddressesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:mac_addresses)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create mac_address" do
    assert_difference('MacAddress.count') do
      post :create, :mac_address => { }
    end

    assert_redirected_to mac_address_path(assigns(:mac_address))
  end

  test "should show mac_address" do
    get :show, :id => mac_addresses(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => mac_addresses(:one).to_param
    assert_response :success
  end

  test "should update mac_address" do
    put :update, :id => mac_addresses(:one).to_param, :mac_address => { }
    assert_redirected_to mac_address_path(assigns(:mac_address))
  end

  test "should destroy mac_address" do
    assert_difference('MacAddress.count', -1) do
      delete :destroy, :id => mac_addresses(:one).to_param
    end

    assert_redirected_to mac_addresses_path
  end
end
