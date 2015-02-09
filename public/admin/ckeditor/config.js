/**
 * @license Copyright (c) 2003-2013, CKSource - Frederico Knabben. All rights reserved.
 * For licensing, see LICENSE.html or http://ckeditor.com/license
 */

CKEDITOR.editorConfig = function( config ) {
	// Define changes to default configuration here.
	// For the complete reference:
	// http://docs.ckeditor.com/#!/api/CKEDITOR.config

	/* Filebrowser routes */
  // The location of an external file browser, that should be launched when "Browse Server" button is pressed.
  config.filebrowserBrowseUrl = "/ckeditor/attachment_files";

  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Flash dialog.
  config.filebrowserFlashBrowseUrl = "/ckeditor/attachment_files";

  // The location of a script that handles file uploads in the Flash dialog.
  config.filebrowserFlashUploadUrl = "/ckeditor/attachment_files";
  
  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Link tab of Image dialog.
  config.filebrowserImageBrowseLinkUrl = "/ckeditor/pictures";

  // The location of an external file browser, that should be launched when "Browse Server" button is pressed in the Image dialog.
  config.filebrowserImageBrowseUrl = "/ckeditor/pictures";

  // The location of a script that handles file uploads in the Image dialog.
  config.filebrowserImageUploadUrl = "/ckeditor/pictures";
  
  // The location of a script that handles file uploads.
  config.filebrowserUploadUrl = "/ckeditor/attachment_files";
  
  // Rails CSRF token
  config.filebrowserParams = function(){
    var csrf_token = jQuery('meta[name=csrf-token]').attr('content'),
        csrf_param = jQuery('meta[name=csrf-param]').attr('content'),
        params = new Object();
    
    if (csrf_param !== undefined && csrf_token !== undefined) {
      params[csrf_param] = csrf_token;
    }
    
    return params;
  };

	config.addQueryString = function (url, params) {
    var queryString = [];

    if (!params)
      return url;
    else {
      for (var i in params)
        queryString.push(i + "=" + encodeURIComponent(params[ i ]));
    }

    return url + ( ( url.indexOf("?") != -1 ) ? "&" : "?" ) + queryString.join("&");
  };

  // Integrate Rails CSRF token into file upload dialogs (link, image, attachment and flash)
  CKEDITOR.on('dialogDefinition', function (ev) {
    // Take the dialog name and its definition from the event data.
    var dialogName = ev.data.name;
    var dialogDefinition = ev.data.definition;
    var content, upload;

    if ($.inArray(dialogName, ['link', 'image', 'attachment', 'flash']) > -1) {
      content = (dialogDefinition.getContents('Upload') || dialogDefinition.getContents('upload'));
      upload = (content == null ? null : content.get('upload'));

      if (upload && upload.filebrowser['params'] == null) {
        upload.filebrowser['params'] = config.filebrowserParams();
        upload.action = config.addQueryString(upload.action, upload.filebrowser['params']);
      }
    }
  });


  // Toolbar configuration generated automatically by the editor based on config.toolbarGroups.
  config.toolbar = [
  	{ name: 'document', items: [ 'Source', '-', 'Iframe' ] },
  	{ name: 'clipboard', groups: [ 'clipboard', 'undo' ], items: [ 'Cut', 'Copy', 'Paste', '-', 'Undo', 'Redo' ] },
  	{ name: 'editing', items: [ 'Find', 'Replace', '-', 'SelectAll' ] },
  	{ name: 'styles', items: [ 'Format', 'Font', 'FontSize' ] },
  	/*{ name: 'forms', items: [ 'Form', 'Checkbox', 'Radio', 'TextField', 'Textarea', 'Select', 'Button', 'ImageButton', 'HiddenField' ] },*/
  	'/',
  	{ name: 'basicstyles', items: [ 'Bold', 'Italic', 'Underline', 'Superscript', 'RemoveFormat', '-', 'TextColor', 'BGColor' ] },
  	{ name: 'paragraph', items: [ 'NumberedList', 'BulletedList', '-', 'Outdent', 'Indent' ] },
  	{ name: 'justify', items: ['JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock' ] },
  	{ name: 'links', items: [ 'Link', 'Unlink', 'Anchor' ] },
  	{ name: 'insert', items: [ 'Image', 'Table', 'SpecialChar' ] }
  ];

  // Toolbar groups configuration.
  config.toolbarGroups = [
  	{ name: 'document', groups: [ 'mode', 'document', 'doctools' ] },
  	{ name: 'clipboard', groups: [ 'clipboard', 'undo' ] },
  	{ name: 'editing', groups: [ 'find', 'selection', 'spellchecker' ] },
  	{ name: 'forms' },
  	'/',
  	{ name: 'basicstyles', groups: [ 'basicstyles', 'cleanup' ] },
  	{ name: 'paragraph', groups: [ 'list', 'indent', 'blocks', 'align', 'bidi' ] },
  	{ name: 'links' },
  	{ name: 'insert' },
  	'/',
  	{ name: 'styles' },
  	{ name: 'colors' },
  	{ name: 'tools' },
  	{ name: 'others' },
  	{ name: 'about' }
  ];
	// Remove some buttons, provided by the standard plugins, which we don't
	// need to have in the Standard(s) toolbar.
	//config.removeButtons = 'Subscript,Superscript';

	// Se the most common block elements.
	config.format_tags = 'p;h1;h2;h3;pre';

	// Make dialogs simpler.
	config.removeDialogTabs = 'image:advanced;link:advanced';
};
