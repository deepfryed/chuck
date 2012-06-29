/*
Version: 0.3.0

Code: https://github.com/deepfryed/jquery.tables
License: Creative Commons Attribution - CC BY, http://creativecommons.org/licenses/by/3.0

Copyright (C) 2011 Bharanee Rathna
*/

(function ($) {
  /** JQueryTables

    A table plugin for jquery that displays data from DOM or dynamic content retrieved via
    xhr requests.

    EXAMPLE
    =======
      <table id="mytable" data-url="/table-data">
        <thead>
          <tr>
            <th data-type="numeric">id</th>
            <th>name</th>
          </tr>
        </thead>
      </table>

      <script src='/js/jquery.tables.js' type='text/javascript'></script>
      <script type='text/javascript'>
        $(function() {
          $('#mytable').tables();
        });
      </script>

    OPTIONS (with defaults)
    =======================

      url: null                           // remote url to fetch data, also respects the data-url attribute for TABLE
      items_per_page: [10, 20, 50, 100]   // display items per page
      sorters: null                       // sort comparison function for custom data types.
                                          //   1. you can provide a data-type attribute in TH for each column.
                                          //   2. by default, jquery.tables.js supports string and numeric types.
                                          //   3. to skip sorting for a column, just add a data-nosort="1" attribute to TH
      i8n:
        display: 'Display'
        first:    'first'
        previous: 'previous'
        next:     'next'
        last:     'last'
        pageinfo: 'Showing {s} to {e} of {t}'
        loading:  'LOADING DATA ...'
        error:    'ERROR LOADING DATA'


    XHR REQUESTS
    ============

      XHR/AJAX requests can return either a JSON or HTML response.

      JSON
      ----

        This needs to have 3 values: total, filtered and rows.
        e.g.
          {total: 92, filtered: 2, rows: [["1", "abby"], ["2", "sam"]]}


      HTML
      ----

        This needs a properly formatted HTML TABLE with the results inside a TBODY element. The total and filtered
        data should be included as attributes for the TABLE.

        e.g.

        <table data-total="92" data-filtered="2">
          <tbody>
            <tr>
              <td>1</td>
              <td>abby</td>
            </tr>
            <tr>
              <td>2</td>
              <td>sam</td>
            </tr>
          </tbody>
        </table>
  */

  var JQueryTables = function(el, options) {
    var table    = $(el);
    var instance = this;
    var settings = options || {};
    var icons    = {0: "ui-icon-carat-2-n-s", 1: "ui-icon-carat-1-n", 2: "ui-icon-carat-1-s"};

    // ordered hash, too bad js doesn't have a built-in.
    var OrderedHash = function() {
      var instance = this;

      this.hash = {};
      this.list = [];

      this.find = function(key) {
        return instance.hash[key];
      };

      this.insert = function(key, value) {
        if (instance.list.indexOf(key) == -1)
          instance.list.push(key);
        instance.hash[key] = value;
      };

      this.delete = function(key) {
        var index = instance.list.indexOf(key);
        if (index >= 0)
          instance.list.splice(index, 1);
        delete instance.hash[key];
      };

      this.size = function() {
        return instance.list.length;
      };

      this.clear = function() {
        instance.hash = {};
        instance.list = [];
      };

      this.values = function() {
        return $.map(instance.list, function(key) { return instance.hash[key]; });
      };

      this.keys = function() {
        return instance.list;
      };
    };

    var i8n = {
      display: 'Display',
      first:    'first',
      previous: 'previous',
      next:     'next',
      last:     'last',
      pageinfo: 'Showing {s} to {e} of {t}',
      loading:  'LOADING DATA ...',
      error:    'ERROR LOADING DATA'
    };

    // pagination & sorting
    settings.items_per_page = settings.items_per_page || [10, 20, 50, 100];
    settings.sorters        = settings.sorters        || {};
    settings.url            = settings.url            || table.attr('data-url');
    settings.i8n            = jQuery.extend(true, settings.i8n || {}, i8n);

    this.page = 0, this.total = 0, this.filtered = 0, this.pages = 0, this.buffer, this.types = [];
    this.limit = settings.items_per_page[0] || table.attr('data-tables-items-per-page');
    this.ordering = new OrderedHash();

    this.init = function() {
      table.wrap($('<div/>', {"class": "jqt-wrapper", "style": "display: inline-block"})).addClass('jqt-table');
      table.attr('cellpadding', 0);
      table.attr('cellspacing', 0);

      this.add_controls();
      this.add_sort_controls();

      // initialize comparison functions & types
      settings.sorters.string = this.strcmp;
      settings.sorters.numeric = this.floatcmp;
      $.each(table.find('thead th'), function(idx, th) { instance.types[idx] = $(th).attr('data-type') || 'string'; });

      this.redraw();
      table.show();
    };

    this.add_sort_controls = function() {
      this.colspan = table.find('thead th').size();

      table.find('thead th').each(function(idx, th) {
        $(th).addClass('ui-state-default');

        if ($(th).attr('data-nosort')) return true;

        var span = $('<span/>', {"class": "ui-icon right " + icons[0]});
        $(th).append(span);
        $(th).click(function(e) {
          var dir = $(th).data('sort-dir');
          dir = dir ? dir % 3 + 1 : 2;

          // toggle betweeb ascending & descending by default.
          if (!e.shiftKey && dir == 1)
            dir = 2;

          $(th).data('sort-dir', dir);

          instance.add_sort_field(e, idx, dir);

          span.removeClass($.map(icons, function(k, v) { return k; }).join(" "));
          span.addClass(icons[dir - 1]);
          instance.redraw();
        });
      });
    };

    this.add_sort_field = function(e, idx, dir) {
      if (!e.shiftKey) {
        $.each(table.find('th > span.ui-icon'), function(idx, el) {
          $(el).removeData();
          $(el).removeClass($.map(icons, function(k, v) { return k; }).join(" "));
          $(el).addClass(icons[0]);
        });

        this.ordering.clear();
        this.ordering.insert(idx, dir);
      }

      if (dir > 1)
        this.ordering.insert(idx, dir);
      else
        this.ordering.delete(idx);
    };

    this.add_controls = function() {
      var uiclass = "ui-toolbar ui-widget-header ui-helper-clearfix";
      table.before(this.top_controls().addClass(uiclass)).after(this.bottom_controls().addClass(uiclass));
    };

    this.top_controls = function() {
      var div = $('<div/>', {"class": "jqt-control top ui-corner-tl ui-corner-tr"});
      var ipp = $('<div/>', {"class": "jqt-ipp"});

      var select = $('<select/>');
      $.each(settings.items_per_page, function(idx, n) { select.append($('<option/>', {html: n})); });

      select.change(function() {
        instance.limit = parseInt($(this).val());
        instance.pages = Math.ceil(instance.filtered / instance.limit);
        if (instance.page >= instance.pages) {
          instance.page = instance.pages - 1;
        }
        instance.redraw();
      });

      var input = $('<input/>', {"name": "q"});

      input.keydown(function(e) {
        if (e.keyCode == 13) {
          instance.query = input.val() == '' ? null : new RegExp(input.val(), "i");
          instance.page = 0;
          instance.redraw();
        }
      });

      var search = $('<div/>', {"class": "query"}).append(input);

      return div.append(ipp.append(settings.i8n.display).append(select)).append(search);
    };

    this.bottom_controls = function() {
      var div = $('<div/>', {"class": "jqt-control bottom ui-corner-bl ui-corner-br"});
      return div;
    };

    // TODO: i18n
    this.fetch_error = function(m) {
      table.trigger('jqt-fetch-error');
      table.find('tbody div.jqt-overlay center').text(settings.i8n.error);
    };

    this.fetch_buffer = function(data, textStatus, jqXHR) {
      table.find('tbody div.jqt-overlay').remove();
      if (typeof(data) == 'string') {
        var $div          = $(data);
        instance.total    = $div.attr('data-total'),
        instance.filtered = $div.attr('data-filtered') || instance.total,
        instance.buffer   = $div.find('tbody');
      }
      else {
        instance.total = data.total, instance.filtered = data.filtered, instance.buffer = $('<tbody/>');
        $.each(data.rows, function(idx, row) {
          var tr = $('<tr/>');
          $.each(row, function(idx, value) { tr.append($('<td/>', {html: value})); });
          instance.buffer.append(tr);
        });
      }
      instance.draw();
    };

    this.display_loading_overlay = function() {
      // remove any previous overlays
      table.find('tbody div.jqt-overlay').remove();

      var message = '<center>' + settings.i8n.loading + '</center>';
      var tbody   = table.find('tbody');

      if (table.find('tbody tr').size() < 1) {
        tbody.html('<tr><td colspan="' + this.colspan + '">' + message + '</td></tr>');
      }
      else {
        var divstyle  = {"z-index": 1, position: 'absolute', height: tbody.innerHeight(), width: tbody.innerWidth()};
        var textstyle = {margin: '25% 0', "font-family": 'Arial'};
        tbody.prepend($('<div/>', {"class": "jqt-overlay"}).append($(message).css(textstyle)).css(divstyle));
      }
    };

    this.fetch = function() {
      var data = {offset: this.page * this.limit, limit: this.limit};

      this.display_loading_overlay();
      this.update_pagination();

      if (this.ordering.size() > 0) {
        data['sf'] = this.ordering.keys();
        data['sd'] = this.ordering.values();
      }

      if (this.query)
        data['q'] = this.query;

      $.ajax({type: 'get', url: settings.url, data: data, error: this.fetch_error, success: this.fetch_buffer});
    };

    this.load = function() {
      // preload buffer only the first time around.
      this.buffer = this.buffer || $('<tbody/>').append(table.find('tbody').html());
      this.total = this.filtered = this.buffer.find('tr').size();
      table.find('tbody').html('');
      this.draw();
    };

    this.draw = function() {
      var rows = this.filter();
      this.filtered = settings.url ? this.filtered : this.query ? rows.size() : this.buffer.find('tr').size();
      this.pages = Math.ceil(this.filtered / this.limit);
      table.find('tbody').html(this.sort(rows).clone());
      this.update_pagination();
      table.trigger('jqt-draw-done');
    };

    this.update_pagination = function() {
      var offset  = this.page * this.limit;
      var toolbar = table.next('.jqt-control.bottom');
      var pagen   = Math.min(offset + this.limit, this.filtered);
      var page    = this.filtered > 0 ? offset + 1 : 0;
      var text    = settings.i8n.pageinfo.replace('{s}', page).replace('{e}', pagen).replace('{t}', this.filtered);

      toolbar.find('.jqt-info').remove();
      toolbar.prepend($('<div/>', {"class": "jqt-info"}).append(text));

      var tbdiv, first, prev, next, last, input;

      if (toolbar.find('.jqt-pagination').size() > 0) {
        first = toolbar.find('.jqt-first');
        prev  = toolbar.find('.jqt-previous');
        next  = toolbar.find('.jqt-next');
        last  = toolbar.find('.jqt-last');
        input = toolbar.find('input');
      }
      else {
        tbdiv = $('<div/>',  {"class": "jqt-pagination"});
        first = $('<span/>', {"class": "jqt-first ui-button ui-state-active", "html": settings.i8n.first});
        prev  = $('<span/>', {"class": "jqt-previous ui-button ui-state-active", "html": settings.i8n.previous});
        next  = $('<span/>', {"class": "jqt-next ui-button ui-state-active", "html": settings.i8n.next});
        last  = $('<span/>', {"class": "jqt-last ui-button ui-state-active", "html": settings.i8n.last});

        first.click(function() {
          if ($(this).is('.ui-state-disabled')) return;
          instance.page = 0;
          instance.redraw();
        });

        prev.click(function() {
          if ($(this).is('.ui-state-disabled')) return;
          instance.page -= 1;
          instance.redraw();
        });

        input = $('<input/>', {placeholder: 'page', style: "font-family:monospace; font-size: 1em;"});
        input.keydown(function(e) {
          if (e.keyCode == 13) {
            var page = parseInt($(this).val());
            if (page > 0 && page <= instance.pages && page != (instance.page + 1)) {
              instance.page = page - 1;
              instance.redraw();
            }
          }
        });

        next.click(function() {
          if ($(this).is('.ui-state-disabled')) return;
          instance.page += 1;
          instance.redraw();
        });

        last.click(function() {
          if ($(this).is('.ui-state-disabled')) return;
          instance.page = instance.pages - 1;
          instance.redraw();
        });

        toolbar.append(tbdiv.append(first).append(prev).append(input).append(next).append(last));
      }

      toolbar.find('.ui-button').removeClass('ui-state-disabled');

      if (this.page == 0) {
        first.addClass('ui-state-disabled');
        prev.addClass('ui-state-disabled');
      }

      if (this.page >= this.pages - 1) {
        next.addClass('ui-state-disabled');
        last.addClass('ui-state-disabled');
      }

      var pagination_index = (instance.pages > 0 ? instance.page + 1 : 0) + ' / ' + instance.pages;
      input.attr({size: pagination_index.length}).val(pagination_index);
    };

    this.filter = function() {
      return settings.url ?
               this.buffer.find('tr') :
               this.query ?
                 this.buffer.find('tr').filter(function(idx) { return $(this).text().match(instance.query); }) :
                 this.buffer.find('tr');
    };

    this.strcmp = function(text1, text2) {
      return text1 > text2 ? 1 : -1;
    };

    this.floatcmp = function(text1, text2) {
      var f1 = parseFloat(text1.replace(/[^-+.0-9]+/g, '')), f2 = parseFloat(text2.replace(/[^-+.0-9]+/g, ''));
      return isNaN(f1) ? 1 : isNaN(f2) ? -1 : f1 == f2 ? 0 : f1 > f2 ? 1 : -1;
    };

    this.datecmp = function(text1, text2) {
      var f1 = Date.parse(text1), f2 = Date.parse(text2);
      return f1 == f2 ? 0 : f1 > f2 ? 1 : -1;
    };

    this.getcolumn = function(tr, idx) {
      return $($(tr).find('td')[idx]).text();
    };

    this.build_sort_function = function() {
      return function(tr1, tr2) {
        var cmp = 0, hash = instance.ordering, multipliers = {1: 0, 2: 1, 3: -1};
        $.each(hash.keys(), function(idx, f) {
          var dir  = multipliers[hash.find(f)], text1 = instance.getcolumn(tr1, f), text2 = instance.getcolumn(tr2, f);

          // dashes always go last if its a numeric field.
          if (instance.types[f] == 'numeric')
            cmp = text1 == '-' ? 1 : text2 == '-' ? -1 : dir * (settings.sorters[instance.types[f]])(text1, text2);
          else
            cmp = dir * (settings.sorters[instance.types[f]])(text1, text2);

          if (cmp != 0) return false;
        });

        return cmp;
      };
    };

    this.sort = function(res) {
      var offset = this.page * this.limit;
      var sorter = this.build_sort_function();
      return settings.url ?
        res :
        this.ordering.size() > 0 ?
          res.sort(sorter).slice(offset, offset + this.limit) :
          res.slice(offset, offset + this.limit);
    };

    this.redraw = function() {
      return settings.url ? this.fetch() : this.load();
    };
  };

  $.fn.tables = function(options) {
    var tables = [];
    var key    = 'jquery.tables';
    $(this).each(function(idx, el) {
      var table = $(el).data(key);
      if (!table) {
        table = new JQueryTables(this, options);
        $(el).data(key, table);
        table.init();
      }
      tables.push(table);
    });

    return tables.length > 1 ? tables : tables[0];
  };

})(jQuery);
