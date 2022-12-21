# How to publish

site with documentation
https://squidfunk.github.io/mkdocs-material/setup/changing-the-logo-and-icons/

## How to install mkdocs
on any server 

clone the repo containing the .md files
```
git clone  https://github.com/accelleran/drax-docs
```

install the tools
``` 
pip3 install mkdocs-material
pip3 install mike
pip3 install mkdocs-section-index
```

create a new site
```
cd drax-docs
mkdocs new site
```

Then start the webservice on the ip address of this server. In our example 10.22.11.147

```
mkdocs serve -a 10.22.11.147:8000     
```

now you can browse using [http:10.22.11.147:8000](http://10.22.11.147:8000/drax-docs/)

## Practically
The drax-docs are cloned on the storage at ```/mnt/5g-backup/drax-docs``` and formatting is applied.
Most of the servers have this mounted. You can also mount it on your local laptop.

Extra formatting is put here aswell. ( not in github yet ) 

Using a tmux window it is easy to generate the mkdocs with the extra formatting.

start the tmux running 
```
cd /mnt/5g-backup/drax-docs
tmux-drax-docs.sh
```

![image](https://user-images.githubusercontent.com/21971027/208913910-b314b3c7-9ba1-40af-b33b-e0d781408ef9.png)


* ```git pull``` : gets the latest changes 
* ```mkdocs serve -a 10.22.11.147:8000``` provides a preview at url ``` http://10.22.11.147:8000/drax-docs/du-install/ ```
* ```mkdocs gh-deploy``` deploys it to github and is available at url ```https://accelleran.github.io/drax-docs/```

## Formatting
extra formatting has been added and is put here 

some formatting changes in ``` drax-docs/mkdocs.yml```. eg: logos
```
.
.
.

theme:                                    
  logo: images/accelleran_logo.png        
  favicon: images/accelleran_favicon.png
.
.
.

```

some formatting changes in ``` drax-docs/docs/css/extra.css```. eg: widening menu tree view
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


