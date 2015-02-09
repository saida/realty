
function datatables(id, url) {
  var defaults = {
    sAjaxSource: url,
		bProcessing: true,
		bServerSide: true,
    iDisplayLength: 100,
    oLanguage: {
      "sProcessing":   "Подождите...",
      "sLengthMenu":   "Показать _MENU_ записей",
      "sZeroRecords":  "Записи отсутствуют.",
      "sInfo":         "Записи с _START_ до _END_ из _TOTAL_ записей",
      "sInfoEmpty":    "Записи с 0 до 0 из 0 записей",
      "sInfoFiltered": "(отфильтровано из _MAX_ записей)",
      "sInfoPostFix":  "",
      "sSearch":       "Поиск:",
      "sUrl":          "",
      "oPaginate": {
          "sFirst": "Первая",
          "sPrevious": "Предыдущая",
          "sNext": "Следующая",
          "sLast": "Последняя"
      },
      "oAria": {
          "sSortAscending":  ": активировать для сортировки столбца по возрастанию",
          "sSortDescending": ": активировать для сортировки столбцов по убыванию"
      }
    }
  };
  var el = $(id);
  var path = url.replace(/\?.*$/, '');
  var target = path.indexOf('/properties') >= 0 ? '_blank' : null;
  el.addClass("table table-striped table-bordered table-hover");

  var buttons = {
    toggle: function(row, active) {
      return "<a class='btn btn-default btn-xs green-stripe toggle' href='#' title='Toggle'><span class='fa" + (active && active != 'f' ? '-eye' : "-eye-slash' style='color:#888'") + "'></span></a> ";
    },
    edit: function(row, url, target) {
      return "<a class='btn btn-default btn-xs green-stripe' href='" + url + "/" + row.DT_RowId + "/edit' title='Edit' target='" + (target || '') +"'><span class='fa-pencil'></span></a> ";
    },
    "delete": function(row, url) {
      return "<a class='btn btn-default btn-xs green-stripe delete' href='" + url + "/" + row.DT_RowId + "' title='Remove'><span class='fa-trash-o'></span></a> ";
    }
  };
  return {
    init: function(options) {
      if (options.reordering) {
        options.bPaginate = options.bPaginate || false;
        options.bSort = options.bSort || false;
        options.bLengthChange = options.bLengthChange || false;
        options.bFilter = options.bFilter || false;
        options.bInfo = options.bInfo || false;
        options.iDisplayLength = options.iDisplayLength || 1000;
        options.aoColumns = [this.columns.sort()].concat(options.aoColumns);
        defaults.sAjaxSource+= (defaults.sAjaxSource.indexOf("?") >= 0 ? "&" : "?") + "with_weight=true";
        for (var i=0; i<options.aoColumns.length; i++)
          options.aoColumns[i].bSortable = false;
      }

  		options.fnRowCallback = options.fnRowCallback || function(nRow, aData, iDisplayIndex) {
  		  if (options.rowCallback) options.rowCallback(nRow, aData, iDisplayIndex);
  		  if (aData.active != undefined)
  		    $('td', nRow).css({opacity: aData.active == false ? 0.5 : 1});

  		  $('a.toggle', nRow).on('click', function() {
          var d = $('span', $(this));
          var res = $.ajax(path + '?toggle=true&id=' + aData.id, {async: false}).responseJSON;
          if (typeof(res) != "boolean") {
            bootbox.alert("ERROR: Couldn't save, it has errors!");
          } else {
            d.removeClass().addClass("fa" + (res ? '-eye' : '-eye-slash'));
            d.css({color:res ? '' : '#888'});
          }
          options.datatable.fnDraw();
          return false;
  		  });

  		  $('a.delete', nRow).on('click', function() {
  		    var url = $(this).attr('href');
  		    bootbox.confirm("Вы уверены?", function(res) {
  		      if (res)
    		      $.ajax(url, {method: 'DELETE', async: false, success: function() {
    		        options.datatable.fnDraw();
    		      }});
  		    });
  		    return false;
  		  });
  		};
  		
      this.datatable = el.dataTable($.extend(defaults, options));
      options.datatable = this.datatable;
      if (options.reordering)
        this.datatable.rowReordering({sURL: path + "?reorder=true", sRequestType: "GET"});
      $(id + '_wrapper .dataTables_filter input').addClass("form-control input-medium");
      $(id + '_wrapper .dataTables_length select').addClass("form-control input-xsmall").select2();
      return this;
    },

    button: function(options) {
      return "<a class='btn btn-default btn-xs green-stripe " + (options["class"] || '') + "' href='" + (options.url || '#') + "' title='" + (options.title || '') + "' style='min-width:24px' target='" + (options.target || '') +"'>" + 
        (options.text || '') + (options.icon ? " <span class='" + options.icon + "'></span>" : "") + "</a> ";
    },
    buttons: buttons,
    columns: {
      sort: function() {
        return {sWidth: "20", bSortable: false, sClass: "center reorder", mRender: function(data, type, row) {
          return "<span class='fa-sort' title='Reorder'></span>";
        }}
      },

      actions: function(options) {
        var os = $.extend({toggle: true, edit: true, trash: true, callback: function(row, button) {return true;}}, options || {});
        return {sWidth: "50", bSortable: false, mRender: function(data, type, row) {
          return (os.prepend ? os.prepend(data, type, row) : "") +
            ((os.toggle === 0 || os.toggle) && os.callback(row, 'toggle') ? buttons.toggle(row, row.active) : "") +
            (os.edit && os.callback(row, 'edit') ? buttons.edit(row, path, target) : "") +
            (os.afteredit ? os.afteredit(data, type, row) : "") +
            (os.trash && os.callback(row, 'trash') ? buttons["delete"](row, path) : "");
        }};
      }
    }
  };
}

(function () {
  'use strict';

  $.fn.datepicker.defaults.format = 'dd.mm.yyyy';
  $.fn.datepicker.defaults.rtl = false;
  $.fn.datepicker.defaults.language = 'ru';
  $.fn.datepicker.defaults.autoclose = true;
  $.fn.datepicker.defaults.todayBtn = true;
  $.fn.datepicker.defaults.todayHighlight = true;
    
  $.fn.datepicker.dates['ru'] = {
		days: ["Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"],
		daysShort: ["Вск", "Пнд", "Втр", "Срд", "Чтв", "Птн", "Суб", "Вск"],
		daysMin: ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"],
		months: ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"],
		monthsShort: ["Янв", "Фев", "Мар", "Апр", "Май", "Июн", "Июл", "Авг", "Сен", "Окт", "Ноя", "Дек"],
		today: "Сегодня",
		weekStart: 1
	};
  
  $('.date-picker').datepicker();

  $('input[type=file]').on('change', function(e, p) {
    if (p == 'clear' && $(this).attr("data-exists")) {
      $(this).removeAttr("data-exists");
      $.post("/admin/base/delete_attachment?target=" + $(this).attr('data-target'));
    }
  });

  $('input[maxlength], textarea[maxlength]').maxlength({
    limitReachedClass: "label label-danger",
    alwaysShow: true
  });

  jQuery.fn.disableSelection = function() {
  	return this.each(function() {
  		$(this).css({
  			'MozUserSelect':'none',
  			'webkitUserSelect':'none'
  		}).attr('unselectable','on').bind('selectstart', function() {
  			return false;
  		});
  	});
  };

  jQuery.fn.enableSelection = function() {
  	return this.each(function() {
  		$(this).css({
  			'MozUserSelect':'',
  			'webkitUserSelect':''
  		}).attr('unselectable','off').unbind('selectstart');
  	});
  };

  jQuery.validator.setDefaults({
    errorElement: 'span',
    errorClass: 'help-block',
    focusInvalid: true,
    ignore: "",

    invalidHandler: function (event, validator) {
    },

    highlight: function (element) {
      $(element).closest('.form-group').addClass('has-error');
    },

    unhighlight: function (element) { // revert the change done by hightlight
      $(element).closest('.form-group').removeClass('has-error');
    },

    success: function (label) {
      label.closest('.form-group').removeClass('has-error');
    }
  });  
  
  $.fn.dataTableExt.oApi.fnFilterClear  = function ( oSettings )
    {
        /* Remove global filter */
        oSettings.oPreviousSearch.sSearch = "";

        /* Remove the text of the global filter in the input boxes */
        if ( typeof oSettings.aanFeatures.f != 'undefined' )
        {
            var n = oSettings.aanFeatures.f;
            for ( var i=0, iLen=n.length ; i<iLen ; i++ )
            {
                $('input', n[i]).val( '' );
            }
        }

        /* Remove the search text for the column filters - NOTE - if you have input boxes for these
         * filters, these will need to be reset
         */
        for ( var i=0, iLen=oSettings.aoPreSearchCols.length ; i<iLen ; i++ )
        {
            oSettings.aoPreSearchCols[i].sSearch = "";
        }

        /* Redraw */
        oSettings.oApi._fnReDraw( oSettings );
    };
})();
