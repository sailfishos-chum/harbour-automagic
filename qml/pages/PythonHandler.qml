import QtQuick 2.0
import io.thp.pyotherside 1.5

Python {
  id: python

  Component.onCompleted: {
    setHandler('error', handle_error);
    setHandler('progress', handle_progress);
    setHandler('success', handle_success);
    setHandler('state_changed', handle_state_changed);
    setHandler('log_received', handle_log_received);

    addImportPath(Qt.resolvedUrl('../../src'));

    importModule('automagic', function () {
      call('automagic.automagic_object.start', []);
    });

  }

  Component.onDestruction: {
    call('automagic.automagic_object.stop', []);
  }

  onError: {
    console.log('ERROR - unhandled error received:', traceback);
  }

  onReceived: {
    console.log('ERROR - unhandled data received:', data);  
  }

  function get_states() {
    call('automagic.automagic_object.get_states', [], function(result) {
        console.log("get_states - states:", JSON.stringify(result))
        
        app.states = result
        app.signal_update_states(result)
     });
  }

  function load_templates() {
    call('automagic.automagic_object.get_templates', [], function(result) {
      app.templates = result
    });
  }
  
  function load_data() {
    call('automagic.automagic_object.load_data', [], function(result) {
      app.settings = result.settings
      app.dynamic_page = String(app.settings.dynamic_page)
      app.data_sources = result.data_sources
      app.actions = result.actions
      app.flows = result.flows
      app.value_maps = result.value_maps

      app.signal_settings_changed(result.settings)
      app.signal_update_data_sources(result.data_sources)
      app.signal_update_actions(result.actions)
      app.signal_update_flows(result.flows)
      app.signal_update_value_maps(result.value_maps)
    });
  }

  function exec_trigger(trigger_id) {
    console.log("exec_trigger - id:", trigger_id)
    call('automagic.automagic_object.exec_trigger', [trigger_id], function(result) {
      console.log("exec_trigger - result:", result)
    });
  }

  function exec_flow(flow_id) {
    console.log("exec_flow - id:", flow_id)
    call('automagic.automagic_object.exec_flow', [flow_id], function(result) {
      console.log("exec_flow - result:", result)
    });
  }

  function daemon_reload() {
    call('automagic.automagic_object.daemon_reload', [], function(result) {
      console.log("daemon_reload - result:", result)
    });
  }

  function save_json_file(data, file_path) {
    var json_data = JSON.stringify({"version": 1, "data": data }, null, 2)
    python.call("automagic.automagic_object.save_text_file", [file_path, json_data])
  }

  function save_flows() {
    save_json_file(app.flows, "flows.json")
  }

  function save_data_sources() {
    save_json_file(app.data_sources, "data_sources.json")
  }

  function save_actions() {
    save_json_file(app.actions, "actions.json")
  }

  function save_value_maps() {
    save_json_file(app.value_maps, "value_maps.json")
  }

  function save_settings() {
    save_json_file(app.settings, "settings.json")
  }

  function handle_error(module_id, method_id, description) {
    console.log('Module ERROR - source:', module_id, method_id, 'error:', description);

    app.signal_error(module_id, method_id, description);
    app.busy = false
  }

  function handle_progress(module_id, method_id, progress_state, message) {
    if (progress_state == "ready") {
      load_templates();
    }
    if (progress_state == "connected") {
      console.log("Daemon status: connected")
      app.connected = true
    }
    if (progress_state == "disconnected") {
      console.log("Daemon status: disconnected")
      app.connected = false
    }
  }

  function handle_success(module_id, method_id, message) {
    app.signal_success(module_id, method_id, message);
    app.busy = false
  }

  function handle_state_changed(state, value) {
    console.log('state:', state, "value:", value);
    app.signal_state_changed(state, value)
  }

  function handle_log_received(flow_id, step_id, run_id, message) {
    console.log("Action_log ( flow:", flow_id, "step:", step_id, "run:", run_id, "):", message);
    app.signal_log_received(flow_id, step_id, run_id, message)
  }
  
}

