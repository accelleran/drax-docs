# How to publish

site with documentation
https://squidfunk.github.io/mkdocs-material/setup/changing-the-logo-and-icons/

## How to install mkdocs
on any server 

clone the repo containing the .md files
```
git clone  https://github.com/accelleran/drax-docs
```

```
curl -sSL https://install.python-poetry.org | python3 -
```

install the tools ( python 3.9 is needed)
``` 
cd drax-docs
poetry shell
```
``` 
poetry install
```
```
mkdocs serve
```

At this point you can start browsing the docs on your local machine

With visual code you can do changes and they will reflect immediatly in the preview on the webbrowser


To make the preview uploaded to git hub use
```
mkdocs gh-deploy
```


## Formatting 
This paragraph shows how the formatting has been accomplished

### for the logos
file ``` drax-docs/mkdocs.yml```. 
```
:
:
theme:                                    
  logo: images/accelleran_logo.png        
  favicon: images/accelleran_favicon.png
:
:
```

### for the menus
file ``` drax-docs/docs/css/extra.css``` 

``` css
.md-typeset img[align=middle], .md-typeset svg[align=middle] {                          
    display: block;                                                                     
    margin: 0 auto;                                                                     
}                                                                                       
.md-grid {                                                                              
        max-width: 71rem                                                                
}                                                                                       
                                                                                        
.md-sidebar {                                                                           
        width: 22.1rem                                                                  
}                                                                                       
                                                                                        
@supports selector(::-webkit-scrollbar) {                                               
    .md-sidebar__scrollwrap {                                                           
        scrollbar-gutter: auto                                                          
    }                                                                                   
                                                                                        
    [dir=ltr] .md-sidebar__inner {                                                      
        padding-right: calc(100% - 21.5rem);                                            
        /* padding-right: 0%; */                                                        
    }                                                                                   
                                                                                        
    [dir=rtl] .md-sidebar__inner {                                                      
        padding-left: calc(100% - 21.5rem)                                              
    }                                                                                   
}                                                                                       
```


