IMAGE := typst-local

# assignments/lab/01-hello-world -> lab-01-hello-world
name = $(subst /,-,$(patsubst assignments/%,%,$(1:/=)))

image:
	docker build -t $(IMAGE) .

# make build DIR=assignments/lab/01-hello-world
build:
	@test -n "$(DIR)" || { echo "Usage: make build DIR=assignments/<path>"; exit 1; }
	@mkdir -p dist
	docker run --rm -v "$$PWD:/work" -w /work $(IMAGE) \
		compile --root /work "$(DIR)/main.typ" "dist/$(call name,$(DIR)).pdf"

# live preview while editing
watch:
	@test -n "$(DIR)" || { echo "Usage: make watch DIR=assignments/<path>"; exit 1; }
	@mkdir -p dist
	docker run --rm -v "$$PWD:/work" -w /work $(IMAGE) \
		watch --root /work "$(DIR)/main.typ" "dist/$(call name,$(DIR)).pdf"

all: image
	@mkdir -p dist
	@find assignments -type f -name main.typ | sort | while read -r f; do \
		name=$$(dirname "$$f" | sed 's|^assignments/||; s|/|-|g'); \
		echo "compile $$name"; \
		docker run --rm -v "$$PWD:/work" -w /work $(IMAGE) \
			compile --root /work "$$f" "dist/$$name.pdf"; \
	done
