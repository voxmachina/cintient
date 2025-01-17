<?php
/*
 *
 *  Cintient, Continuous Integration made simple.
 *  Copyright (c) 2010, 2011, Pedro Mata-Mouros Fonseca
 *
 *  This file is part of Cintient.
 *
 *  Cintient is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Cintient is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Cintient. If not, see <http://www.gnu.org/licenses/>.
 *
 */

/**
 * An echo task, for printing out messages into the output console or
 * specified file.
 *
 * @package     Build
 * @subpackage  Task
 * @author      Pedro Mata-Mouros Fonseca <pedro.matamouros@gmail.com>
 * @copyright   2010-2011, Pedro Mata-Mouros Fonseca.
 * @license     http://www.gnu.org/licenses/gpl-3.0.html GNU GPLv3 or later.
 * @version     $LastChangedRevision$
 * @link        $HeadURL$
 * Changed by   $LastChangedBy$
 * Changed on   $LastChangedDate$
 */
class Build_BuilderElement_Task_Echo extends Build_BuilderElement
{
  protected $_message;
  protected $_file;            // If present, message will be written to this file
  protected $_append;          // The directory in which the command should be executed in

  public function __construct()
  {
    parent::__construct();
    $this->_message = null;
    $this->_file = null;
    $this->_append = true;
  }

	/**
   * Creates a new instance of this builder element, with default values.
   */
  static public function create()
  {
    return new self();
  }

  public function toAnt()
  {
    if (!$this->getMessage()) {
      SystemEvent::raise(SystemEvent::ERROR, 'Message not set for echo task.', __METHOD__);
      return false;
    }
    $xml = new XmlDoc();
    $xml->startElement('echo');
    if ($this->getFile()) {
      $xml->writeAttribute('file', $this->getFile());
      if ($this->getAppend() !== null) {
        $xml->writeAttribute('append', ($this->getAppend()?'true':'false'));
      }
    } else {
      $xml->text($this->getMessage());
    }
    $xml->endElement();
    return $xml->flush();
  }

  public function toHtml()
  {
    parent::toHtml();
    if (!$this->isVisible()) {
      return true;
    }
    $o = $this;
    h::li(array('class' => 'builderElement', 'id' => $o->getInternalId()), function() use ($o) {
      $o->getHtmlTitle(array('title' => 'Echo'));
      h::div(array('class' => 'builderElementForm'), function() use ($o) {
        // Message, textfield
        h::div(array('class' => 'label'), 'Message');
        h::div(array('class' => 'textfieldContainer'), function() use ($o) {
          h::input(array('class' => 'textfield', 'type' => 'text', 'name' => 'message', 'value' => $o->getMessage()));
        });
        // File, textfield
        h::div(array('class' => 'label'), 'File');
        h::div(array('class' => 'textfieldContainer'), function() use ($o) {
          h::input(array('class' => 'textfield', 'type' => 'text', 'name' => 'file', 'value' => $o->getFile()));
        });
        // Append, checkbox
        h::div(array('class' => 'label'), 'Append?');
        h::div(array('class' => 'checkboxContainer'), function() use ($o) {
          $params = array('class' => 'checkbox', 'type' => 'checkbox', 'name' => 'append',);
          if ($o->getAppend()) {
            $params['checked'] = 'checked';
          }
          h::input($params);
        });
      });
    });
  }

  public function toPhing()
  {
    return $this->toAnt();
  }

  public function toPhp(Array &$context = array())
  {
    $php = '';
    if (!$this->getMessage()) {
      SystemEvent::raise(SystemEvent::ERROR, 'Message not set for echo task.', __METHOD__);
      return false;
    }
    $php .= "
\$GLOBALS['result']['task'] = 'echo';
";
    $msg = addslashes($this->getMessage());
    $php .= "
\$getMessage = expandStr('{$msg}');
";
    if ($this->getFile()) {
      $append = 'w'; // the same as append == false (default for Ant and Phing)
      if ($this->getAppend()) {
        $append = 'a';
      }
      $php .= <<<EOT
\$getFile = expandStr('{$this->getFile()}');
if (!(\$fp = @fopen(\$getFile, '{$append}'))) {
  output("Couldn't open file \$getFile for output.");
  if ({$this->getFailOnError()}) {
    \$GLOBALS['result']['ok'] = false;
    return false;
  } else {
    \$GLOBALS['result']['ok'] = \$GLOBALS['result']['ok'] & true;
  }
}
\$res = (fwrite(\$fp, \$getMessage) === false ?:true);
fclose(\$fp);
if (!\$res) {
  output("Couldn't write message to file.");
  if ({$this->getFailOnError()}) {
    \$GLOBALS['result']['ok'] = false;
    return false;
  } else {
    \$GLOBALS['result']['ok'] = \$GLOBALS['result']['ok'] & true;
  }
} else {
  \$GLOBALS['result']['ok'] = \$GLOBALS['result']['ok'] & true;
}
EOT;
    } else {
      $php .= <<<EOT
\$GLOBALS['result']['ok'] = \$GLOBALS['result']['ok'] & true;
output(\$getMessage);
EOT;
    }
    return $php;
  }
}