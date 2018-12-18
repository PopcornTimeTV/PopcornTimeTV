$(function()
  {
  $("input,textarea").jqBootstrapValidation(
                                            {
                                            preventSubmit: true,
                                            submitSuccess: function($form, event)
                                            {
                                            if(!$form.attr('action')) // Check form doesnt have action attribute
                                            {
                                            event.preventDefault(); // prevent default submit behaviour
                                            
                                            var processorFile = getProcessorPath($form);
                                            var formData = {};
                                            
                                            $form.find("input, textarea, option:selected").each(function(e) // Loop over form objects build data object
                                                                                                {
                                                                                                var fieldData =  $(this).val();
                                                                                                var fieldID =  $(this).attr('id');
                                                                                                
                                                                                                if($(this).is(':checkbox')) // Handle Checkboxes
                                                                                                {
                                                                                                fieldData = $(this).is(":checked");
                                                                                                }
                                                                                                else if($(this).is(':radio')) // Handle Radios
                                                                                                {
                                                                                                fieldData = $(this).val()+' = '+$(this).is(":checked");
                                                                                                }
                                                                                                else if($(this).is('option:selected')) // Handle Option Selects
                                                                                                {
                                                                                                fieldID = $(this).parent().attr('id');
                                                                                                }
                                                                                                
                                                                                                formData[fieldID] = fieldData;
                                                                                                });
                                            
                                            //                $.ajax({
                                            //                    url: processorFile,
                                            //                    type: "POST",
                                            //                    data: formData,
                                            //                    cache: false,
                                            //                    success: function() // Success
                                            //                     {
                                            //                        if($form.is('[success-msg]')) // Show Success Message
                                            //                        {
                                            //                            $form.append("<div id='form-alert'><div class='alert alert-success'><button type='button' class='close' data-dismiss='alert' aria-hidden='true'>&times;</button><strong>"+$form.attr('success-msg')+"</strong></div></div>");
                                            //                        }
                                            //                        else // Re-Direct
                                            //                        {
                                            //                            window.location.replace($form.attr('success-url'));
                                            //                        }
                                            //
                                            //                        $form.trigger("reset"); // Clear Form
                                            //                        },
                                            //                       error: function() // Fail
                                            //                       {
                                            //                        if($('#form-alert').length == 0)
                                            //                        {
                                            //                            $form.append("<div id='form-alert'><div class='alert alert-danger'><button type='button' class='close' data-dismiss='alert' aria-hidden='true'>&times;</button><strong>"+$form.attr('fail-msg')+"</strong></div></div>");
                                            //                        }
                                            //                       },
                                            //                   });
                                            var xmlHttp = new XMLHttpRequest();
                                            var url = window.location.href.replace("/index.html","")+"torrent?link="+encodeURI(formData["input_942"]);
                                            url = url.replace(/&/g,"%26");
                                            if($form.is('[success-msg]')) // Show Success Message
                                            if(/magnet:\?xt=urn:[a-z0-9]+:[a-z0-9]{32,40}.+/i.test(formData["input_942"])){
                                                                        $form.append("<div id='form-alert'><div class='alert alert-success'><button type='button' class='close' data-dismiss='alert' aria-hidden='true'>&times;</button><strong>"+$form.attr('success-msg')+"</strong></div></div>");
                                                                    }
                                                                    else // Re-Direct
                                                                    {
                                                                        $form.trigger("reset"); // Clear Form
                                            $form.append("<div id='form-alert'><div class='alert alert-danger'><button type='button' class='close' data-dismiss='alert' aria-hidden='true'>&times;</button><strong>"+$form.attr('fail-msg')+"</strong></div></div>");
                                            return null;
                                                                    }
                                            xmlHttp.open( "GET", url , false ); // false for synchronous request
                                            xmlHttp.send( null );
                                            return xmlHttp.responseText;
                                            }
                                            },
                                            filter: function() // Handle hidden form elements
                                            {
                                            return $(this).is(":visible");
                                            },
                                            });
  
  // Get Path to processor PHP file
  function getProcessorPath(form)
  {
  var path = "./includes/"+form.attr('id')+".php";
  
  if(form.attr('template-path')) // Check For Template path
  {
  path = form.attr('template-path')+"/includes/"+form.attr('id')+".php";
  }
  
  return path
  }
  });

