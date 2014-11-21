<%@page import="javax.jcr.PropertyType"%>
<%@page import="javax.jcr.nodetype.PropertyDefinition"%>
<%@page import="javax.jcr.security.Privilege"%>
<%@page import="javax.jcr.security.AccessControlManager"%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@page import="java.util.List"%>
<%@page import="java.util.ArrayList"%>
<%@page import="javax.jcr.Value"%>
<%@page import="javax.jcr.Property"%>
<%@page import="javax.jcr.PropertyIterator"%>
<%@page import="javax.jcr.Session"%>
<%@page session="false" contentType="text/html; charset=utf-8"
	trimDirectiveWhitespaces="true"%>
<%@taglib prefix="sling" uri="http://sling.apache.org/taglibs/sling"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn"%>
<sling:defineObjects />
<c:set var="staticRoot" value="/apps/browser/static" scope="request" />
<!DOCTYPE html>
<html lang="en">
<head>
<title>${currentNode.name}</title>
 <meta name="viewport" content="width=device-width, initial-scale=1.0">
 <link href="${staticRoot}/bootstrap-3.3.0/css/bootstrap.min.css" rel="stylesheet" media="screen">
 <style>
 .table>thead>tr>th {
 	border-top:none;
 }
 .container {
 	margin-right: 0;
	margin-left: 0;
	background-color: #fff;
	border-color: #ddd;
	border-width: 1px;
	border-radius: 4px 4px 0 0;
	-webkit-box-shadow: none;
	box-shadow: none;
 }
 
 .readonly {
 	opacity:0.6;
 }
 
 .value-edit {
 	display:none;
 }
 
 .value-edit textarea {
 	width: 80%;
	resize: vertical;
 }
 
 .editing {
 	-webkit-user-select:none;
 	user-select:none;
 }
 .editing .value-edit {
 	display:block;
 }
 .editing .value-display {
 	display:none;
 }
 
 .divclearable {
    border: 1px solid #888;
    display: -moz-inline-stack;
    display: inline-block;
    zoom:1;
    *display:inline;
    padding-right:5px;
    vertical-align:middle;
}
  
a.clearlink {
    background: url("close-button.png") no-repeat scroll 0 0 transparent;
    background-position: center center;
    cursor: pointer;
    display: -moz-inline-stack;
    display: inline-block;
    zoom:1;
    *display:inline;
    height: 12px;
    width: 12px;
    z-index: 2000;
    border: 0px solid;
}

 </style>
  <script type="text/javascript" src="${staticRoot}/jquery-2.1.1.min.js"></script>
</head>
<body>
	<div class="container">
		<table class="table table-condensed">
			<tbody>
				<thead>
					<tr>
						<th>Name</th>
						<th>Type</th>
						<th>Value</th>
						<%--><th>Status</th> --%>
						<th>Action</th>
					</tr>
				</thead>
						
			<%
				PropertyIterator properties = currentNode.getProperties();
				String primaryType = currentNode.getProperty("jcr:primaryType").getString();
				String resourceType = resource.getResourceType();
				String path = currentNode.getPath();
				if (properties != null) {
					Session session = currentNode.getSession();
					/*
					AccessControlManager acm = currentNode.getSession().getAccessControlManager();
					Privilege[] privileges = acm.getPrivileges(currentNode.getPath());
					for (int i=0;i<privileges.length;i++) {
						out.println(privileges[i].getName());
					}
					*/
					while (properties.hasNext()) {
						Property p = properties.nextProperty();
						PropertyDefinition propertyDefinition = p.getDefinition();
						String name = p.getName();
						String[] values = null;
						
						String readonlyClass = (propertyDefinition.isProtected() || name.equals("jcr:data")) ? "readonly" : "";
						if (p.isMultiple()) {
							Value v[] = p.getValues();
							values =  new String[v.length];
							for (int i = 0; i < v.length; i++) {
								values[i] = v[i].getString();
							}
							
						} else {
							values = new String[1];
							values[0] = name.equals("jcr:data") ? "binary" : p.getString();
						}
						String propertyType = PropertyType.nameFromValue(propertyDefinition.getRequiredType());
			%>
				<tr class="<%=readonlyClass%>" data-name="<%=name%>" data-type="<%=propertyType %>" data-multiple="<%=p.isMultiple() %>" >
					<td><%=name%></td>
					<td><%=propertyType %><%= propertyDefinition.isMultiple()?"[]": "" %></td>
					<td>
						<div class="value-display"><%= StringUtils.join(values,", ") %></div>
						<div class="value-edit">
							<% for (String value:values) { %>
							<span><%=value%></span>
							<% } %>
						</div>
					</td>
					<%--
					<td>[
						 protected: <%= propertyDefinition.isProtected() %>, 
						 autoCreated: <%= propertyDefinition.isAutoCreated() %>, 
						 mandatory: <%= propertyDefinition.isMandatory() %>
						 ]
					</td>
					 --%>
					<td class="actions">
						<% if (!(propertyDefinition.isProtected() || name.equals("jcr:data"))) { %>
							<span class="glyphicon glyphicon-remove" title="delete this property"></span> 
						<% } %>
					</td>
				</tr>
			<%
					}
				}
			%>
			</tbody>
		</table>
	</div>
	<form id="propertyForm" class="form-horizontal" method="post"
		action="${resource.path}" enctype="multipart/form-data">
		<fieldset>
			<input type="hidden" name=":redirect"
				value="<%=slingRequest.getRequestURL()%>" /> <input type="hidden"
				name=":errorpage" value="<%=slingRequest.getRequestURL()%>" />
		</fieldset>
	</form>
	
	<script>
		$('tr:not(.readonly)').on('dblclick', function() {
			var _self = $(this);
			_self.toggleClass('editing');
			if (!_self.data('renderForm')) {
				_self.data('renderForm',true);
				createEditPanel(_self);
			}
			//11509761175
		})
		// JCR PropertyDefinition String,Date,Binary,Double,Long,Boolean,Name,Path,Reference,Undefined
		function createEditPanel(trElement) {
			var name = trElement.data('name');
			var type = trElement.data('type');
			var isMultiple =  trElement.data('multiple')
			var valueEdit = trElement.find('.value-edit');
			var out = [];
			if (!isMultiple) {
				var val = valueEdit.find('span').text();
				if (type == 'Boolean') {
					out.push('<input type="checkbox" name="'+name+'" value="'+val+'" checked="'+val+'" />');
				} else if (type == 'Reference') {
					//TODO
				} else if (type == 'Date') {
					//TODO
				} else if (type == 'Name') {
					//TODO
				} else {
					out.push('<textarea name="'+name+'">'+val+'</textarea>');
				}
			} else {
				
			}
		 	valueEdit.empty().append(out.join(''));
		}
		
	 	function openEdit(event) {
	 		event.preventDefault();
	 		var field = $(this).attr('data-field');
	 		var fieldValue = dataJson[field];
	 		var fieldSet = $("#dialog-edit fieldset")
	 		fieldSet.empty();
	 		$("#dialog-edit").dialog('option','title','FIELD: '+field);
	 		if (fieldValue instanceof Array) {
	 			for (var i in fieldValue) {
	 				$('<input type="text" />').attr('name',field).attr('value',fieldValue[i]).appendTo(fieldSet);
	 			}
	 			fieldSet.children().each(function() {	
				$(this).css({'border-width': '0px', 'outline': 'none', 'border-spacing':'5px'})
					.wrap('<div class="divclearable"></div>')
					.parent()
					.attr('class', $(this).attr('class') + ' divclearable')
					.append('<a class="clearlink" href="#"></a>');
			
				$('.clearlink')
					.attr('title', 'Click to clear this textbox')
					.click(function(event) {
						event.preventDefault();
						$(this).parent().remove();
					});
				  });
	 		} else if (fieldValue.indexOf('<') > -1) {
	 			var textarea  = $('<textarea></textarea>').attr('name',field).attr('value',fieldValue).appendTo(fieldSet);
	 			textarea.wysiwyg({
					rmUnusedControls: true,
					controls: {
						bold: { visible : true },
						html: { visible : true },
						italic: {visible: true},
						insertOrderedList: { visible: true},
						insertUnorderedList: {visible: true},
						undo: {visible: true},
						redo: {visible: true},
						removeFormat: { visible : true }
					}
				});
	 		} else {
	 			$('<input type="text"/>').attr('name',field).attr('value',fieldValue).appendTo(fieldSet);
	 		}
	 		
	 		 $("#dialog-edit").dialog('open');
	 	}
	 	
		
	
	</script>

</body>
</html>