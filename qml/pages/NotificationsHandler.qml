import QtQuick 2.0
import Nemo.Notifications 1.0
import Sailfish.Silica 1.0

Item {
  id: notifications_handler

  Notice {                                                                                                                                             
    id: error_notice                                                                                                                                                                                                                                                 
    anchor: Notice.Top
    duration: Notice.Long                                                                                                                            
  }

  Notice {                                                                                                                                             
    id: success_notice                                                                                                                                                                                                                                                 
    anchor: Notice.Top
    duration: Notice.Long                                                                                                                            
  }

  Component.onCompleted: {
    app.signal_error.connect(error_handler)
    app.signal_success.connect(success_handler)
  }

  Component.onDestruction: {
    app.signal_error.disconnect(error_handler)
    app.signal_success.disconnect(success_handler)
  }

  function error_handler(module_id, method_id, description) {
    console.log('error_handler - source:', module_id, method_id, 'error:', description);
    error_notice.text = description
    error_notice.show()
  }

  function success_handler(module_id, method_id, description) {
    console.log('success_handler - source:', module_id, method_id, 'description:', description);
    success_notice.text = description
    success_notice.show()
  }
}