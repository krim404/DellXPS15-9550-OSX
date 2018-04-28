/*
 * jsTreeGrid 0.98
 * http://jsorm.com/
 *
 * This plugin handles adding a grid to a tree to display additional data
 *
 * Dual licensed under the MIT and GPL licenses (same as jQuery):
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 * 
 * Created for Tufin www.tufin.com
 * Contributed to public source through the good offices of Tufin
 * Edited by: SOVA
 *
 * $Date: 2013-05-15 $
 * $Revision:  $
 */

/*jslint nomen:false */
/*global window, document, jQuery*/

(function ($) {
	var renderAWidth, renderATitle, htmlstripre, SPECIAL_TITLE = "_DATA_", bound = false, styled = false;
	/*jslint regexp:false */
	htmlstripre = /<\/?[^>]+>/gi;
	/*jslint regexp:true */

	renderAWidth = function(node,tree) {
		var depth, a = node.get(0).tagName.toLowerCase() === "a" ? node : node.children("a"),
		width = parseInt(tree.data.grid.columns[0].width) + parseInt(tree.data.grid.treeWidthDiff);
		// need to use a selector in jquery 1.4.4+
		depth = a.parentsUntil(tree.get_container().get(0).tagName+".jstree").filter("li").length;
		width = width - depth*18;
		a.css({width: width, "vertical-align": "top", "overflow":"hidden","float":"left"});
	};
	renderATitle = function(node,t,tree) {
		var a = node.get(0).tagName.toLowerCase() === "a" ? node : node.children("a"), title, col = tree.data.grid.columns[0];
		// get the title
		title = "";
		if (col.title) {
			if (col.title === SPECIAL_TITLE) {
				title = tree.get_text(t);
			} else if (t.attr(col.title)) {
				title = t.attr(col.title);
			}
		}
		// strip out HTML
		title = title.replace(htmlstripre, '');
		if (title) {
			a.attr("title",title);
		}
	};

	$.jstree.plugin("grid", {
		__init : function () { 
			var s = this._get_settings().grid || {}, styles;
			this.data.grid.columns = s.columns || []; 
			this.data.grid.treeClass = "jstree-grid-col-0";
			this.data.grid.columnWidth = s.width;
			this.data.grid.defaultConf = {display: "inline-block","*display":"inline","*+display":"inline","float":"left"};
			this.data.grid.isThemeroller = !!this.data.themeroller;
			this.data.grid.treeWidthDiff = 0;
			this.data.grid.resizable = s.resizable;
			
			var msie = /msie/.test(navigator.userAgent.toLowerCase());
			if (msie) {
				var version = parseFloat(navigator.appVersion.split("MSIE")[1]);
				if (version < 8) {
					this.data.grid.defaultConf.display = "inline";
					this.data.grid.defaultConf.zoom = "1";
				}
			}
			
			// set up the classes we need
			if (!styled) {
				styled = true;
				styles = [
					/* '.jstree-grid-cell {padding-left: 4px; vertical-align: top; overflow:hidden;}', */   /* blackosx changed this to below */
					'.jstree-grid-cell {padding-right: 4px; vertical-align: top; white-space:normal; word-break: break-all;  }', 
					
					'.jstree-grid-separator {display: inline-block; border-width: 0 2px 0 0; *display:inline; *+display:inline; margin-right:0px;float:left;}',
					'.jstree-grid-header-cell {float: left;}',
					'.jstree-grid-header-themeroller {border: 0; padding: 1px 3px;}',
					'.jstree-grid-header-regular {background-color: #EBF3FD;}',
					'.jstree-grid-resizable-separator {cursor: col-resize;}',
					'.jstree-grid-separator-regular {border-color: #d0d0d0; border-style: solid;}',
					'.jstree-grid-cell-themeroller {border: none !important; background: transparent !important;}'
				];

				$('<style type="text/css">'+styles.join("\n")+'</style>').appendTo("head");
			}

			this.get_container().bind("open_node.jstree create_node.jstree clean_node.jstree change_node.jstree", $.proxy(function (e, data) { 
					var target = data && data.rslt && data.rslt.obj ? data.rslt.obj : e.target;
					target = $(target);
					this._prepare_grid(target);
				}, this))
			.bind("loaded.jstree", $.proxy(function (e) {
				this._prepare_headers();
				this._prepare_grid();
				this.get_container().trigger("loaded_grid.jstree");
				}, this))
			.bind("move_node.jstree",$.proxy(function(e,data){
				var node = data.rslt.o;
				renderAWidth(node,this);
				// check all the children, because we could drag a tree over
				node.find("li > a").each($.proxy(function(i,elm){
					renderAWidth($(elm),this);
				},this));
				
			},this));
			if (this.data.grid.isThemeroller) {
				this.get_container()
					.bind("select_node.jstree",$.proxy(function(e,data){
						data.rslt.obj.children("a").nextAll("div").addClass("ui-state-active");
					},this))
					.bind("deselect_node.jstree deselect_all.jstree",$.proxy(function(e,data){
						data.rslt.obj.children("a").nextAll("div").removeClass("ui-state-active");
					},this))
					.bind("hover_node.jstree",$.proxy(function(e,data){
						data.rslt.obj.children("a").nextAll("div").addClass("ui-state-hover");
					},this))
					.bind("dehover_node.jstree",$.proxy(function(e,data){
						data.rslt.obj.children("a").nextAll("div").removeClass("ui-state-hover");
					},this));
			}
			
		},
		__destroy : function() {
			var parent = this.data.grid.parent, container = this.get_container();
			container.detach();
			$("div.jstree-grid-wrapper",parent).remove();
			parent.append(container);
		},
		defaults : {
			width: 25
		},
		_fn : { 
			_prepare_headers : function() {
				var header, i, cols = this.data.grid.columns || [], width, defaultWidth = this.data.grid.columnWidth, resizable = this.data.grid.resizable || false,
				cl, val, margin, last, tr = this.data.grid.isThemeroller, classAdd = (tr?"themeroller":"regular"),
				cHeight, hHeight, container = this.get_container(), parent = container.parent(), hasHeaders = 0,
				conf = this.data.grid.defaultConf, isClickedSep = false, oldMouseX = 0, newMouseX = 0, currentTree = null, colNum = 0, toResize = null, clickedSep = null, borPadWidth = 0;
				// save the original parent so we can reparent on destroy
				this.data.grid.parent = parent;
				
				
				// set up the wrapper, if not already done
				header = this.data.grid.header || $("<div></div>").addClass((tr?"ui-widget-header ":"")+"jstree-grid-header jstree-grid-header-"+classAdd);
				
				// create the headers
				for (i=0;i<cols.length;i++) {
					cl = cols[i].headerClass || "";
					val = cols[i].header || "";
					if (val) {hasHeaders = true;}
					width = cols[i].width || defaultWidth;
					borPadWidth = tr ? 1+6 : 2+8; // account for the borders and padding
					width -= borPadWidth;
					margin = i === 0 ? 3 : 0;
					last = $("<div></div>").css(conf).css({"margin-left": margin,"width":width, "padding": "1 3 2 5"}).addClass((tr?"ui-widget-header ":"")+"jstree-grid-header jstree-grid-header-cell jstree-grid-header-"+classAdd+" "+cl).text(val).appendTo(header)
						.after("<div class='jstree-grid-separator jstree-grid-separator-"+classAdd+(tr ? " ui-widget-header" : "")+(resizable? " jstree-grid-resizable-separator":"")+"'>&nbsp;</div>");
				}
				last.addClass((tr?"ui-widget-header ":"")+"jstree-grid-header jstree-grid-header-"+classAdd);
				// add a clearer
				$("<div></div>").css("clear","both").appendTo(header);
				// did we have any real columns?
				if (hasHeaders) {
					$("<div></div>").addClass("jstree-grid-wrapper").appendTo(parent).append(header).append(container);
					// save the offset of the div from the body
					this.data.grid.divOffset = header.parent().offset().left;
					this.data.grid.header = header;
				}

				if (!bound && resizable) {
					bound = true;
					$(document).on("selectstart", ".jstree-grid-separator", function () { return false; });
					$(document).on("mousedown", ".jstree-grid-separator", function (e) {
							clickedSep = $(this);
							isClickedSep = true;
							currentTree = clickedSep.parents(".jstree-grid-wrapper").children(".jstree");
							oldMouseX = e.clientX;
							colNum = clickedSep.prevAll(".jstree-grid-header").length-1;
							toResize = clickedSep.prev().add(currentTree.find(".jstree-grid-col-"+colNum));
							return false;
						});
					$(document)
						.mouseup(function () {
							var  i, ref, cols, widths, headers;
							if (isClickedSep) {
								ref = $.jstree._reference(currentTree);
								cols = ref.data.grid.columns;
								headers = clickedSep.parent().children(".jstree-grid-header");
								widths = {};
								if (!colNum) { ref.data.grid.treeWidthDiff = currentTree.find("ins:eq(0)").width() + currentTree.find("a:eq(0)").width() - ref.data.grid.columns[0].width; }
								isClickedSep = false;
								for (i=0;i<cols.length;i++) { widths[cols[i].header] = {w: parseFloat(headers[i].style.width)+borPadWidth, r: i===colNum }; }
								currentTree.trigger("resize_column.jstree-grid", [widths]);
							}
						})
						.mousemove(function (e) {
							if (isClickedSep) {
								newMouseX = e.clientX;
								var diff = newMouseX - oldMouseX;
								toResize.each(function () { this.style.width = parseFloat(this.style.width) + diff + "px"; });
								oldMouseX = newMouseX;
							}
						});
				}
			},
			_prepare_grid : function(obj) {
				var c = this.data.grid.treeClass, _this = this, t, cols = this.data.grid.columns || [], width, tr = this.data.grid.isThemeroller, 
				classAdd = (tr?"themeroller":"regular"), img,
				defaultWidth = this.data.grid.columnWidth, divOffset = this.data.grid.divOffset, conf = this.data.grid.defaultConf;
				obj = !obj || obj === -1 ? this.get_container() : this._get_node(obj);
				// get our column definition
				obj.each(function () {
					var i, val, cl, wcl, a, last, valClass, wideValClass, span, paddingleft, title, isAlreadyGrid, col, content, s, tmpWidth;
					t = $(this);
					
					// find the a children
					a = t.children("a");
					isAlreadyGrid = a.hasClass(c);
					
					if (a.length === 1) {
					  a.prev().css("float","left");
						a.addClass(c);
						renderAWidth(a,_this);
						renderATitle(a,t,_this);
						last = a;
						for (i=1;i<cols.length;i++) {
							col = cols[i];
							s = col.source || "attr";
							// get the cellClass and the wideCellClass
							cl = col.cellClass || "";
							wcl = col.wideCellClass || "";


							// get the contents of the cell
							if (s === "attr") { val = col.value && t.attr(col.value) ? t.attr(col.value) : "";
							} else if (s === "metadata") { val = col.value && t.data(col.value) ? t.data(col.value) : ""; }

							// put images instead of text if needed
							if (col.images) {
							img = col.images[val] || col.images["default"];
							if (img) {content = img[0] === "*" ? '<span class="'+img.substr(1)+'"></span>' : '<img src="'+img+'">';}
							} else { content = val; }

							// get the valueClass
							valClass = col.valueClass && t.attr(col.valueClass) ? t.attr(col.valueClass) : "";
							if (valClass && col.valueClassPrefix && col.valueClassPrefix !== "") {
								valClass = col.valueClassPrefix + valClass;
							}
							// get the wideValueClass
							wideValClass = col.wideValueClass && t.attr(col.wideValueClass) ? t.attr(col.wideValueClass) : "";
							if (wideValClass && col.wideValueClassPrefix && col.wideValueClassPrefix !== "") {
								wideValClass = col.wideValueClassPrefix + wideValClass;
							}
							// get the title
							title = col.title && t.attr(col.title) ? t.attr(col.title) : "";
							// strip out HTML
							title = title.replace(htmlstripre, '');
							
							// get the width
							paddingleft = 7;
							width = col.width || defaultWidth;
							tmpWidth = $.support.boxModel ? $(".jstree-grid-col-"+i+":first",t).width() : $(".jstree-grid-col-"+i+":first",t).outerWidth();
							width = tmpWidth || (width - paddingleft);
							
							last = isAlreadyGrid ? a.nextAll("div:eq("+(i-1)+")") : $("<div></div>").insertAfter(last);
							// Blackosx changed the following span to div because appending to the span was causing a double event to be fired when using select_cell.jstree-grid. 
							//span = isAlreadyGrid ? last.children("span") : $("<span></span>").appendTo(last);
							span = isAlreadyGrid ? last.children("span") : $("<div></div>").appendTo(last);

							// create a span inside the div, so we can control what happens in the whole div versus inside just the text/background
							
							// Blackosx - Changing click to mouseover also works, if preferred.
							// span.addClass(cl+" "+valClass).css({"margin-right":"0px","display":"inline-block","*display":"inline","*+display":"inline"}).html(content).click((function (val,col,s) {
							   span.addClass(cl+" "+valClass).css({"margin-right":"0px","display":"inline-block","*display":"inline","*+display":"inline","cursor":"pointer"}).html(content).click((function (val,col,s) {
							
								return function() {
									//$(this).trigger("select_cell.jstree-grid", [{value: val,column: col.header,node: $(this).closest("li"),sourceName: col.value,sourceType: s}]);
									//Blackosx changed to this as per: https://github.com/deitch/jstree-grid/issues/20
									//$(this).trigger("select_cell.jstree-grid", [val,col.header,$(this).closest("li"),col.value,s]);
									$(this).trigger("select_cell.jstree-grid", [val]);
								};
							}(val,col,s)));
							last = last.css(conf).css({width: width,"padding-left":paddingleft+"px"}).addClass("jstree-grid-cell jstree-grid-cell-"+classAdd+" "+wcl+ " " + wideValClass + (tr?" ui-state-default":"")).addClass("jstree-grid-col-"+i);
							
							if (title) {
								span.attr("title",title);
							}

						}		
						last.addClass("jstree-grid-cell-last"+(tr?" ui-state-default":""));
						$("<div></div>").css("clear","both").insertAfter(last);
					}
				});
				if(obj.is("li")) { this._repair_state(obj); }
				else { obj.find("> ul > li").each(function () { _this._repair_state(this); }); }
   				$('.jstree').css({'overflow-y':'auto !important'});

				// Blackosx - Add this here for third column adjust on window resize.
				$(window).on('resize', function (e) {	
				    toResize = $("#rightPaneTree").find(".jstree-grid-col-"+2);
				    thirdColumnWidth = $("#rightPaneTree").width();
				    // minus the 1st and 2nd column widths and extra 40px for spacing and scroll bar.
				    // Note: Extra 30px was okay for Mac but IE 9 required 40px.
				    // So that will be 240+80+40 = 350
				    thirdColumnWidth=Math.round(thirdColumnWidth)-360;
				    toResize.each(function () { this.style.width = thirdColumnWidth + "px"; });
				});
				// Blackosx - Also add here outside of resizing window so it works when window is refreshed.
				toResize = $("#rightPaneTree").find(".jstree-grid-col-"+2);
				thirdColumnWidth = $("#rightPaneTree").width();
				thirdColumnWidth=Math.round(thirdColumnWidth)-360;
				toResize.each(function () { this.style.width = thirdColumnWidth + "px"; });
			}
		}
		// need to do alternating background colors or borders
	});
}(jQuery));