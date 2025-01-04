# パラメーターを自動でラップする機能を無効化する
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: []
end
