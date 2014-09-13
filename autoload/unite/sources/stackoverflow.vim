let s:save_cpo = &cpo
set cpo&vim

let g:unite_source_stackoverflow_search_limit = get(g:, 'unite_source_stackoverflow_search_limit', 100)

let s:source = {
            \ 'name' : 'stackoverflow',
            \ 'description' : 'Search stackoverflow.com',
            \ 'default_kind' : 'uri',
            \ 'default_action' : {'uri' : 'start'},
            \ 'hooks' : {},
            \ }

function! unite#sources#stackoverflow#define()
    return has('ruby') ? s:source : {}
endfunction

function! s:type(args)
    if empty(a:args)
        return "intitle"
    endif

    return a:args[0] ==# "tags" ? "tags" : "intitle"
endfunction

function! s:source.hooks.on_init(args, context)
    let t = s:type(a:args)
    let a:context.stackoverflow__type = t
    let a:context.stackoverflow__input = input(t ==# 'tags' ? "tags(separate by ';'): " : 'query: ')
endfunction

function! s:source.gather_candidates(args, context)

    let candidates = []

ruby << EOF
    require 'rubygems' if RUBY_VERSION < "1.9"
    require 'json'
    require 'net/http'

    module StackOverflow
    module API extend self

        def search(query, type)
            api_get "/2.2/search?order=desc&sort=votes&#{type}=#{URI::encode query}&site=stackoverflow"
        end

        private

        def api_get(path)
            u = URI::parse("https://api.stackexchange.com" + path)
            Net::HTTP.start(u.host, u.port, :use_ssl => true) do |http|
                response = http.get u.request_uri
                return JSON(response.body)['items']
            end
        end

    end
    end

    type = VIM::evaluate 'a:context.stackoverflow__type'

    StackOverflow::API::search(VIM::evaluate('a:context.stackoverflow__input'), type).each do |item|
        VIM::evaluate "add(candidates, {'word' : \"#{URI::decode item['title']}\", 'action__uri' : \"#{item['link']}\"})"
    end
EOF

    return candidates
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
