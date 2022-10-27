# Changelog

{{ range .Versions }}

## {{ .Tag.Name }}

{{ range .CommitGroups -}}

### {{ .Title }}

{{ range .Commits -}}

- {{ if .Scope }}**{{ .Scope }}:** {{ end }}{{ .Subject }}

{{ end }}{{ end -}}

{{- if .NoteGroups -}}
{{ range .NoteGroups -}}

### {{ .Title }}

{{ range .Notes }}
{{ .Body }}
{{ end }}
{{ end -}}
{{ end -}}

{{ if .Tag.Previous }}
**Full changelog*: [{{ .Tag.Name }}]({{ $.Info.RepositoryURL }}/compare/{{ .Tag.Previous.Name }}...{{ .Tag.Name }})
{{ end }}

{{ end -}}
