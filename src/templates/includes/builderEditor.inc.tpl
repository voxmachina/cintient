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
{function name=builderElement depth=0}
{if is_array($element)}
{if $depth!=0}
              <li>
                <h1>{key($element)}</h1>
                <ul class="builderElementDepth_{$depth}">
{$element=current($element)}
{/if}
{foreach $element as $key => $value}
{if is_array($value)}
{builderElement element=[$key => $value] depth=$depth+1}
{else}
                  <li>{$value}</li>
{/if}
{/foreach}
{if $depth!=0}
                </ul>
              </li>
{/if}
{else}
              <li>{$element}</li>
{/if}
{/function}
            <ul class="builderElementDepth_0">
{TemplateManager::providerAvailableBuilderElements()}
{builderElement element=$providerAvailableBuilderElements_elements}
            </ul>
          </div>
      
          <div class="builderElementsChosen">
{$globals_project->getIntegrationBuilder()->toHtml()}
          </div>
<script type="text/javascript">
// <![CDATA[
$(document).ready(function() {
	//
  // Set up elements animation
  //
  $('.builderElementTitle p.title').click(function() {
    if ($(this).parent('.builderElementTitle').next().is(':visible')) {
      $(this).parent('.builderElementTitle').next().fadeOut(110);
    } else {
    	$(this).parent('.builderElementTitle').next().fadeIn(200);
    }
    return false;
  }).parent('.builderElementTitle').next().hide();
  //
	// Set up submit links
  //
  $('.builderElementTitle a.submit').live('click', function(e) {
      e.preventDefault();
      var that = this;
      var data = function() {
        var x = {};
        $(that).parents('.builderElementTitle').next('.builderElementForm').find('form input').each( function() {
          x[this.name] = { type: this.type, value: this.value };
        });
        return x;
      }();
      $.ajax({
        url: $(this).parents('.builderElementTitle').next('.builderElementForm').find('form').attr('action'),
        data: data,
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
  });
});
//]]> 
</script>
