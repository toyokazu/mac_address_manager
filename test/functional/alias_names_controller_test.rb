require 'test_helper'

class AliasNamesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:alias_names)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create alias_name" do
    assert_difference('AliasName.count') do
      post :create, :alias_name => { }
    end

    assert_redirected_to alias_name_path(assigns(:alias_name))
  end

  test "should show alias_name" do
    get :show, :id => alias_names(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => alias_names(:one).to_param
    assert_response :success
  end

  test "should update alias_name" do
    put :update, :id => alias_names(:one).to_param, :alias_name => { }
    assert_redirected_to alias_name_path(assigns(:alias_name))
  end

  test "should destroy alias_name" do
    assert_difference('Alias.count', -1) do
      delete :destroy, :id => alias_names(:one).to_param
    end

    assert_redirected_to alias_names_path
  end
end
