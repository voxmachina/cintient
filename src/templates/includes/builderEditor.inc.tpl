{*
    Cintient, Continuous Integration made simple.
    Copyright (c) 2010, 2011, Pedro Mata-Mouros Fonseca

    This file is part of Cintient.

    Cintient is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Cintient is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Cintient. If not, see <http://www.gnu.org/licenses/>.

*}

          <div class="builderElementsAvailable">
{function name=builderElement depth=0 context=''}
{if is_array($element)}
{if $depth!=0}
              <li>
                <h1>{key($element)}</h1>
                <ul class="builderElementDepth_{$depth}">
{$element=current($element)}
{/if}
{foreach $element as $key => $value}
{if is_array($value)}
{$originalContext=$context}
{$context="{$context}_$key"}
{builderElement element=[$key => $value] depth=$depth+1 context=$context}
{$context=$originalContext}
{else}
                  <li><a href="#" class="{$context}">{$value}</a></li>
{/if}
{/foreach}
{if $depth!=0}
                </ul>
              </li>
{/if}
{else}
              <li><a href="#" class="{$context}">{$element}</a></li>
{/if}
{/function}
            <ul class="builderElementDepth_0">
{TemplateManager::providerAvailableBuilderElements()}
{builderElement element=$providerAvailableBuilderElements_elements}
            </ul>
          </div>

          <ul id="sortable" class="builderElementsChosen">
{$globals_project->getIntegrationBuilder()->toHtml()}
          </ul>
<script type="text/javascript">
// <![CDATA[
$(document).ready(function() {
	//
  // Set up elements animation
  //
  $('.builderElementTitle p.title').live('click', function() {
    if ($(this).parent('.builderElementTitle').next().is(':visible')) {
      $(this).parent('.builderElementTitle').next().fadeOut(110);
    } else {
    	$(this).parent('.builderElementTitle').next().fadeIn(200);
    }
    return false;
  }).parent('.builderElementTitle').next().hide();
  //
	// Show save links on change
  //
  $('.builderElementForm input').live('change keyup', function(e) {
    // TODO: in case of keyup event, only activate save in case something
    // was written (prevent tab, cursor, etc). Better yet, only in case
    // the value has become different from the original.
    $(this).parents('.builderElement').find('.builderElementTitle a.submit').fadeIn(100);
  });
  //
	// Register click events for save links
  //
  $('.builderElementTitle a.submit').live('click', function(e) {
    e.preventDefault();
    var that = this;
    var data = function() {
      var x = {};
      $(that).parents('.builderElement').find('.builderElementForm input').each( function() {
        x[this.name] = { type: this.type, value: this.value };
      });
      $(that).parents('.builderElement').find('.builderElementForm textarea').each( function() {
        x[this.name] = { type: this.type, value: this.value };
      });
      x['internalId'] = { type: 'hidden', value: $(that).parents('.builderElement').attr('id') };
      $(that).parents('.builderElement').find('.builderElementForm input:radio[name=type]:checked').each( function() {
    	  x['type'] = { type: 'radio', value: $(this).val() }; // This overwrites the previous input iteration with the correct value for type
      });
      return x;
    }();
    $.ajax({
      url: '{UrlManager::getForAjaxProjectIntegrationBuilderSaveElement()}',
      data: data,
      type: 'POST',
      cache: false,
      dataType: 'json',
      success: function(data, textStatus, XMLHttpRequest) {
        if (!data.success) {
          //TODO: treat this properly
          alert('error');
        } else {
          $(that).fadeOut(300);
          $.jGrowl($(that).parents('.builderElementTitle').find('.title').text() + " builder element saved.");
          //alert('ok');
        }
      },
      error: function(XMLHttpRequest, textStatus, errorThrown) {
        alert(errorThrown);
      }
    });
  });
  //
	// Set up remove links
  //
  $('.builderElementTitle a.delete').live('click', function(e) {
    e.preventDefault();
    var that = this;
    $.ajax({
      url: '{UrlManager::getForAjaxProjectIntegrationBuilderDeleteElement()}',
      data: { internalId: $(this).parents('.builderElement').attr('id') },
      type: 'POST',
      cache: false,
      dataType: 'json',
      success: function(data, textStatus, XMLHttpRequest) {
        if (!data.success) {
          //TODO: treat this properly
          alert('error');
        } else {
        	$(that).parents('.builderElement').fadeOut(350);
        	setTimeout(
    		    function() {
    		    	$(that).parents('.builderElement').remove();
    		    },
    		    300 // Slightly faster than the fadeOut, so that the next items get pulled up before the element fades first
    		  );
        }
      },
      error: function(XMLHttpRequest, textStatus, errorThrown) {
        alert(errorThrown);
      }
    });
  });
  //
  // Set up add links
  //
  $('.builderElementsAvailable a').click(function(e) {
    e.preventDefault();
    $.ajax({
      url: '{UrlManager::getForAjaxProjectIntegrationBuilderAddElement()}',
      data: { task: $(this).text(), parent: $(this).attr('class') },
      type: 'POST',
      cache: false,
      dataType: 'html',
      success: function(data, textStatus, XMLHttpRequest) {
        $('.builderElementsChosen').append(data);
      },
      error: function(XMLHttpRequest, textStatus, errorThrown) {
        alert(errorThrown);
      }
    });
  });

  //
  // Setup sorting
  //
  var builderElementsChosen = $('#sortable');

  // Enable sorting
  builderElementsChosen.sortable(
    {
      axis: 'y',
      cursor: 'move',
      //cursorAt: 'top',
      disabled: false,
      distance: 20,
      //items: '.builderElement',
      opacity: 0.6,
      //placeholder: 'ui-state-highlight',
      //revert: 100,
      scroll: true,
      stop: function(event, ui) {
    	  var newSort = builderElementsChosen.sortable('toArray');
        if (newSort.join('') != initialSort.join('')) { // is toString() equally ubiquous?
        	$.ajax({
    	      url: '{UrlManager::getForAjaxProjectIntegrationBuilderSortElements()}',
    	      data: { sortedElements: newSort },
    	      type: 'POST',
    	      cache: false,
    	      dataType: 'json',
    	      success: function(data, textStatus, XMLHttpRequest) {
    	        if (!data.success) {
    	          //TODO: treat this properly
    	          alert('error');
    	        } else {
    	          //alert('ok');
    	        }
    	      },
    	      error: function(XMLHttpRequest, textStatus, errorThrown) {
    	        alert(errorThrown);
    	      }
    	    });
        }
     	},
      tolerance: 'pointer',
    }
  );

  // Get initial sort in order to detect changes
  initialSort = builderElementsChosen.sortable('toArray');
});
//]]>
</script>
