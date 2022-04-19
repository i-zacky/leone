package example;

import lombok.SneakyThrows;
import org.springframework.boot.Banner;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;

@SpringBootApplication
public class Application {

  @SneakyThrows
  public static void main(String[] args) {
    new SpringApplicationBuilder(Application.class) //
        .bannerMode(Banner.Mode.OFF) //
        .build() //
        .run(args);
  }
}
