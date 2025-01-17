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
    <div id="projectHeader">
      <div class="projectAvatar40x40"><img src="{$globals_project->getAvatarUrl()}" width="40" height="40"></div>
      <div id="statusContainer"><div class="triggerBuild status projectStatus{if $project->getStatus()==Project::STATUS_OK}Ok{elseif $project->getStatus()==Project::STATUS_BUILDING}Working{elseif $project->getStatus()==Project::STATUS_UNINITIALIZED}Uninitialized{else}Failed{/if}"><div class="projectStatusWaiting"></div></div></div>
      <div class="title">{$project->getTitle()}</div>
{if !empty($project_build)}
      <div id="buildListDropdownLink">
        <div id="projectStatus_{$project->getId()}" class="details">
          #{$project_build->getId()}, rev {$project_build->getScmRevision()},
          on {$project_build->getDate()|date_format:"%b %e, %Y at %R"}
        </div>
        <div class="dropdownTriangle"></div>
      </div>

      <div id="buildList" class="popupWidget">
{if !empty($project_buildList)}
        <table>
          <tbody>
{foreach from=$project_buildList item=build}
{$currentDate=$build->getDate()|date_format:"%b %e, %Y"}
{if $currentDate != $lastDate}
            <tr class="date">
              <th colspan="3">{$currentDate}</th>
            </tr>
{/if}
            <tr class="{UrlManager::getForProjectBuildView($globals_project, $build)}">
              <td><dt class="{if $build->getStatus()!=Project_Build::STATUS_FAIL}buildOk{else}buildFail{/if}">{$build->getDate()|date_format:"%R"}</dt></td>
              <td>#{$build->getId()}</td>
              <td>rev {$build->getScmRevision()}</td>
            </tr>
{$lastDate=$build->getDate()|date_format:"%b %e, %Y"}
{/foreach}
          </tbody>
        </table>
{/if}
      </div>

{elseif $globals_project->userHasAccessLevel($globals_user, Access::BUILD) || $globals_user->hasCos(UserCos::ROOT)}
      <div id="projectStatus_{$project->getId()}" class="details">
        Click <a href="#" class="triggerBuild">here</a> to trigger the first build for this project.
      </div>
{/if}
    </div>
{if $globals_project->userHasAccessLevel($globals_user, Access::BUILD) || $globals_user->hasCos(UserCos::ROOT)}
<script type="text/javascript">
//<![CDATA[
projectLastKnownStatus = {$globals_project->getStatus()};
updateProjectStatus(projectLastKnownStatus);
function forceBuild()
{
  updateProjectStatus({Project::STATUS_BUILDING});
  //
  // XHR trigger the build
  //
  $.ajax({
    url: '{UrlManager::getForAjaxProjectBuild()}',
    cache: false,
    dataType: 'json',
    done: function (x, s) {
      console.log('done: ' + s);
    },
    fail: function (x, s) {
      console.log('fail: ' + s);
    },
    complete: function (x, s) {
      console.log('complete: ' + s);
    },
    success: function(data, textStatus, XMLHttpRequest) {
      console.log('success: ' + textStatus);
      if (data == null || data.success == null || data.projectStatus == null) {
        $.jGrowl("An unknown error occurred!", { header: "Warning", sticky: true });
        data = {
          success: false,
          projectStatus: projectLastKnownStatus
        };
      } else if (data.success) {
        $.jGrowl("Build finished successfully.");
      } else {
        $.jGrowl("Build failed!", { header: "Warning", life: 10000 });
      }
      updateProjectStatus(data.projectStatus);
    },
    error: function(XMLHttpRequest, textStatus, errorThrown) {
      console.log('error: ' + textStatus);

      if (textStatus == 'parsererror') {
        $.jGrowl("An error occurred!", { header: "Warning", sticky: true });
      } else {
        $.jGrowl("An unknown error occurred!", { header: "Warning", sticky: true });
      }
      updateProjectStatus(projectLastKnownStatus);
    }
  });

}

function updateProjectStatus(toStatus)
{
  switch(toStatus) {
  case {Project::STATUS_OK}:
    projectLastKnownStatus = toStatus;
    $('#projectHeader #statusContainer .projectStatusWaiting').fadeOut(50);
    $('#projectHeader #statusContainer .status').removeClass('projectStatusFailed projectStatusWorking');
    $('#projectHeader #statusContainer .status').addClass('projectStatusOk');
    break;
  case {Project::STATUS_BUILDING}:
    $('#projectHeader #statusContainer .status').removeClass('projectStatusFailed projectStatusOk');
    $('#projectHeader #statusContainer .status').addClass('projectStatusWorking');
    $('#projectHeader #statusContainer .projectStatusWaiting').fadeIn(150);
    break;
  default:
    projectLastKnownStatus = toStatus;
    $('#projectHeader #statusContainer .projectStatusWaiting').fadeOut(50);
    $('#projectHeader #statusContainer .status').removeClass('projectStatusWorking projectStatusOk');
    $('#projectHeader #statusContainer .status').addClass('projectStatusFailed');
    break;
  }
}

$(document).ready(function() {
  //
  // Bind the project status icon to the build link
  //
  $('#projectHeader .triggerBuild')
    .hover(
      function() {
        $(this).css({
          "cursor" : "pointer",
        });
      },
      function() {
        $(this).css({
          "cursor" : "default",
        });
      })
    .click(function(e) {
      e.stopPropagation();
      forceBuild();
    });

  //
  // The build list dropdown
  //
  buildListActive = false;
  $('#buildListDropdownLink').hover(
	  function() {
      $(this).css({
    	  "cursor" : "pointer"
      });
    },
    function() {
    	$(this).css({
    	  "cursor" : "default"
      });
    }
  );
  $('#buildListDropdownLink').click( function(e) {
    if (buildListActive) {
    	$('#buildList').fadeOut(50);
    } else {
      $('#buildList').fadeIn(50);
    }
    buildListActive = !buildListActive;
    e.stopPropagation();
  });
  $('#buildList table tr:not([class=date])').each( function() {
  	$(this).click(function() {
      pane = '';
      if (typeof activeResultPane !== 'undefined') {
    	  pane = '#' + $(activeResultPane).attr('id');
      }
  		window.location = $(this).attr('class') + pane;
    });
  	$(this).hover(
  		function() {
        $(this).css({
      	  "cursor" : "pointer",
          "color" : "#555",
        	"text-shadow" : "1px 1px 1px #fff",
          "background" : "#ddd"
        });
      },
      function() {
      	$(this).css({
      	  "cursor" : "default",
          "color" : "#fff",
      		"text-shadow" : "1px 1px 1px #303030",
          "background" : "transparent"
        });
      }
    );
  });

  // Close any menus on click anywhere on the page
  $(document).click(function(){
    if (buildListActive) {
      $('#buildList').fadeOut(50);
      buildListActive = false;
    }
  });
});
// ]]>
</script>
{/if}